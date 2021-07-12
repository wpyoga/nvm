nvm_ls_remote() {
  local PATTERN
  PATTERN="${1-}"
  if nvm_validate_implicit_alias "${PATTERN}" 2>/dev/null ; then
    local IMPLICIT
    IMPLICIT="$(nvm_print_implicit_alias remote "${PATTERN}")"
    if [ -z "${IMPLICIT-}" ] || [ "${IMPLICIT}" = 'N/A' ]; then
      nvm_echo "N/A"
      return 3
    fi
    PATTERN="$(NVM_LTS="${NVM_LTS-}" nvm_ls_remote "${IMPLICIT}" | command tail -1 | command awk '{ print $1 }')"
  elif [ -n "${PATTERN}" ]; then
    PATTERN="$(nvm_ensure_version_prefix "${PATTERN}")"
  else
    PATTERN=".*"
  fi
  NVM_LTS="${NVM_LTS-}" nvm_ls_remote_index_tab node std "${PATTERN}"
}

nvm_ls_remote_iojs() {
  NVM_LTS="${NVM_LTS-}" nvm_ls_remote_index_tab iojs std "${1-}"
}

# args flavor, type, version
nvm_ls_remote_index_tab() {
  local LTS
  LTS="${NVM_LTS-}"
  if [ "$#" -lt 3 ]; then
    nvm_err 'not enough arguments'
    return 5
  fi

  local FLAVOR
  FLAVOR="${1-}"

  local TYPE
  TYPE="${2-}"

  local MIRROR
  MIRROR="$(nvm_get_mirror "${FLAVOR}" "${TYPE}")"
  if [ -z "${MIRROR}" ]; then
    return 3
  fi

  local PREFIX
  PREFIX=''
  case "${FLAVOR}-${TYPE}" in
    iojs-std) PREFIX="$(nvm_iojs_prefix)-" ;;
    node-std) PREFIX='' ;;
    iojs-*)
      nvm_err 'unknown type of io.js release'
      return 4
    ;;
    *)
      nvm_err 'unknown type of node.js release'
      return 4
    ;;
  esac
  local SORT_COMMAND
  SORT_COMMAND='command sort'
  case "${FLAVOR}" in
    node) SORT_COMMAND='command sort -t. -u -k 1.2,1n -k 2,2n -k 3,3n' ;;
  esac

  local PATTERN
  PATTERN="${3-}"

  if [ "${PATTERN#"${PATTERN%?}"}" = '.' ]; then
    PATTERN="${PATTERN%.}"
  fi

  local VERSIONS
  if [ -n "${PATTERN}" ] && [ "${PATTERN}" != '*' ]; then
    if [ "${FLAVOR}" = 'iojs' ]; then
      PATTERN="$(nvm_ensure_version_prefix "$(nvm_strip_iojs_prefix "${PATTERN}")")"
    else
      PATTERN="$(nvm_ensure_version_prefix "${PATTERN}")"
    fi
  else
    unset PATTERN
  fi

  nvm_is_zsh && setopt local_options shwordsplit
  local VERSION_LIST
  VERSION_LIST="$(nvm_download -L -s "${MIRROR}/index.tab" -o - \
    | command sed "
        1d;
        s/^/${PREFIX}/;
      " \
  )"
  local LTS_ALIAS
  local LTS_VERSION
  command mkdir -p "$(nvm_alias_path)/lts"
  nvm_echo "${VERSION_LIST}" \
    | command awk '{
        if ($10 ~ /^\-?$/) { next }
        if ($10 && !a[tolower($10)]++) {
          if (alias) { print alias, version }
          alias_name = "lts/" tolower($10)
          if (!alias) { print "lts/*", alias_name }
          alias = alias_name
          version = $1
        }
      }
      END {
        if (alias) {
          print alias, version
        }
      }' \
    | while read -r LTS_ALIAS_LINE; do
      LTS_ALIAS="${LTS_ALIAS_LINE%% *}"
      LTS_VERSION="${LTS_ALIAS_LINE#* }"
      nvm_make_alias "${LTS_ALIAS}" "${LTS_VERSION}" >/dev/null 2>&1
    done

  VERSIONS="$({ command awk -v lts="${LTS-}" '{
        if (!$1) { next }
        if (lts && $10 ~ /^\-?$/) { next }
        if (lts && lts != "*" && tolower($10) !~ tolower(lts)) { next }
        if ($10 !~ /^\-?$/) {
          if ($10 && $10 != prev) {
            print $1, $10, "*"
          } else {
            print $1, $10
          }
        } else {
          print $1
        }
        prev=$10;
      }' \
    | nvm_grep -w "${PATTERN:-.*}" \
    | $SORT_COMMAND; } << EOF
$VERSION_LIST
EOF
)"
  if [ -z "${VERSIONS}" ]; then
    nvm_echo 'N/A'
    return 3
  fi
  nvm_echo "${VERSIONS}"
}
