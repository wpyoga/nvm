nvm_print_versions() {
  local VERSION
  local LTS
  local FORMAT
  local NVM_CURRENT
  local NVM_LATEST_LTS_COLOR
  local NVM_OLD_LTS_COLOR

  local INSTALLED_COLOR
  local SYSTEM_COLOR
  local CURRENT_COLOR
  local NOT_INSTALLED_COLOR
  local DEFAULT_COLOR
  local LTS_COLOR

  INSTALLED_COLOR=$(nvm_get_colors 1)
  SYSTEM_COLOR=$(nvm_get_colors 2)
  CURRENT_COLOR=$(nvm_get_colors 3)
  NOT_INSTALLED_COLOR=$(nvm_get_colors 4)
  DEFAULT_COLOR=$(nvm_get_colors 5)
  LTS_COLOR=$(nvm_get_colors 6)

  NVM_CURRENT=$(nvm_ls_current)
  NVM_LATEST_LTS_COLOR=$(nvm_echo "${CURRENT_COLOR}" | command tr '0;' '1;')
  NVM_OLD_LTS_COLOR="${DEFAULT_COLOR}"
  local NVM_HAS_COLORS
  if [ -z "${NVM_NO_COLORS-}" ] && nvm_has_colors; then
    NVM_HAS_COLORS=1
  fi
  local LTS_LENGTH
  local LTS_FORMAT
  nvm_echo "${1-}" \
  | command sed '1!G;h;$!d' \
  | command awk '{ if ($2 && $3 && $3 == "*") { print $1, "(Latest LTS: " $2 ")" } else if ($2) { print $1, "(LTS: " $2 ")" } else { print $1 } }' \
  | command sed '1!G;h;$!d' \
  | while read -r VERSION_LINE; do
    VERSION="${VERSION_LINE%% *}"
    LTS="${VERSION_LINE#* }"
    FORMAT='%15s'
    if [ "_${VERSION}" = "_${NVM_CURRENT}" ]; then
      if [ "${NVM_HAS_COLORS-}" = '1' ]; then
        FORMAT="\033[${CURRENT_COLOR}-> %12s\033[0m"
      else
        FORMAT='-> %12s *'
      fi
    elif [ "${VERSION}" = "system" ]; then
      if [ "${NVM_HAS_COLORS-}" = '1' ]; then
        FORMAT="\033[${SYSTEM_COLOR}%15s\033[0m"
      else
        FORMAT='%15s *'
      fi
    elif nvm_is_version_installed "${VERSION}"; then
      if [ "${NVM_HAS_COLORS-}" = '1' ]; then
        FORMAT="\033[${INSTALLED_COLOR}%15s\033[0m"
      else
        FORMAT='%15s *'
      fi
    fi
    if [ "${LTS}" != "${VERSION}" ]; then
      case "${LTS}" in
        *Latest*)
          LTS="${LTS##Latest }"
          LTS_LENGTH="${#LTS}"
          if [ "${NVM_HAS_COLORS-}" = '1' ]; then
            LTS_FORMAT="  \\033[${NVM_LATEST_LTS_COLOR}%${LTS_LENGTH}s\\033[0m"
          else
            LTS_FORMAT="  %${LTS_LENGTH}s"
          fi
        ;;
        *)
          LTS_LENGTH="${#LTS}"
          if [ "${NVM_HAS_COLORS-}" = '1' ]; then
            LTS_FORMAT="  \\033[${NVM_OLD_LTS_COLOR}%${LTS_LENGTH}s\\033[0m"
          else
            LTS_FORMAT="  %${LTS_LENGTH}s"
          fi
        ;;
      esac
      command printf -- "${FORMAT}${LTS_FORMAT}\\n" "${VERSION}" " ${LTS}"
    else
      command printf -- "${FORMAT}\\n" "${VERSION}"
    fi
  done
}

nvm_validate_implicit_alias() {
  local NVM_IOJS_PREFIX
  NVM_IOJS_PREFIX="$(nvm_iojs_prefix)"
  local NVM_NODE_PREFIX
  NVM_NODE_PREFIX="$(nvm_node_prefix)"

  case "$1" in
    "stable" | "unstable" | "${NVM_IOJS_PREFIX}" | "${NVM_NODE_PREFIX}")
      return
    ;;
    *)
      nvm_err "Only implicit aliases 'stable', 'unstable', '${NVM_IOJS_PREFIX}', and '${NVM_NODE_PREFIX}' are supported."
      return 1
    ;;
  esac
}

nvm_print_implicit_alias() {
  if [ "_$1" != "_local" ] && [ "_$1" != "_remote" ]; then
    nvm_err "nvm_print_implicit_alias must be specified with local or remote as the first argument."
    return 1
  fi

  local NVM_IMPLICIT
  NVM_IMPLICIT="$2"
  if ! nvm_validate_implicit_alias "${NVM_IMPLICIT}"; then
    return 2
  fi

  local NVM_IOJS_PREFIX
  NVM_IOJS_PREFIX="$(nvm_iojs_prefix)"
  local NVM_NODE_PREFIX
  NVM_NODE_PREFIX="$(nvm_node_prefix)"
  local NVM_COMMAND
  local NVM_ADD_PREFIX_COMMAND
  local LAST_TWO
  case "${NVM_IMPLICIT}" in
    "${NVM_IOJS_PREFIX}")
      NVM_COMMAND="nvm_ls_remote_iojs"
      NVM_ADD_PREFIX_COMMAND="nvm_add_iojs_prefix"
      if [ "_$1" = "_local" ]; then
        NVM_COMMAND="nvm_ls ${NVM_IMPLICIT}"
      fi

      nvm_is_zsh && setopt local_options shwordsplit

      local NVM_IOJS_VERSION
      local EXIT_CODE
      NVM_IOJS_VERSION="$(${NVM_COMMAND})" &&:
      EXIT_CODE="$?"
      if [ "_${EXIT_CODE}" = "_0" ]; then
        NVM_IOJS_VERSION="$(nvm_echo "${NVM_IOJS_VERSION}" | command sed "s/^${NVM_IMPLICIT}-//" | nvm_grep -e '^v' | command cut -c2- | command cut -d . -f 1,2 | uniq | command tail -1)"
      fi

      if [ "_$NVM_IOJS_VERSION" = "_N/A" ]; then
        nvm_echo 'N/A'
      else
        ${NVM_ADD_PREFIX_COMMAND} "${NVM_IOJS_VERSION}"
      fi
      return $EXIT_CODE
    ;;
    "${NVM_NODE_PREFIX}")
      nvm_echo 'stable'
      return
    ;;
    *)
      NVM_COMMAND="nvm_ls_remote"
      if [ "_$1" = "_local" ]; then
        NVM_COMMAND="nvm_ls node"
      fi

      nvm_is_zsh && setopt local_options shwordsplit

      LAST_TWO=$($NVM_COMMAND | nvm_grep -e '^v' | command cut -c2- | command cut -d . -f 1,2 | uniq)
    ;;
  esac
  local MINOR
  local STABLE
  local UNSTABLE
  local MOD
  local NORMALIZED_VERSION

  nvm_is_zsh && setopt local_options shwordsplit
  for MINOR in $LAST_TWO; do
    NORMALIZED_VERSION="$(nvm_normalize_version "$MINOR")"
    if [ "_0${NORMALIZED_VERSION#?}" != "_$NORMALIZED_VERSION" ]; then
      STABLE="$MINOR"
    else
      MOD="$(awk 'BEGIN { print int(ARGV[1] / 1000000) % 2 ; exit(0) }' "${NORMALIZED_VERSION}")"
      if [ "${MOD}" -eq 0 ]; then
        STABLE="${MINOR}"
      elif [ "${MOD}" -eq 1 ]; then
        UNSTABLE="${MINOR}"
      fi
    fi
  done

  if [ "_$2" = '_stable' ]; then
    nvm_echo "${STABLE}"
  elif [ "_$2" = '_unstable' ]; then
    nvm_echo "${UNSTABLE:-"N/A"}"
  fi
}
