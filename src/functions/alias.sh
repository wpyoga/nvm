nvm_print_formatted_alias() {
  local ALIAS
  ALIAS="${1-}"
  local DEST
  DEST="${2-}"
  local VERSION
  VERSION="${3-}"
  if [ -z "${VERSION}" ]; then
    VERSION="$(nvm_version "${DEST}")" ||:
  fi
  local VERSION_FORMAT
  local ALIAS_FORMAT
  local DEST_FORMAT

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

  ALIAS_FORMAT='%s'
  DEST_FORMAT='%s'
  VERSION_FORMAT='%s'
  local NEWLINE
  NEWLINE='\n'
  if [ "_${DEFAULT}" = '_true' ]; then
    NEWLINE=' (default)\n'
  fi
  local ARROW
  ARROW='->'
  if [ -z "${NVM_NO_COLORS}" ] && nvm_has_colors; then
    ARROW='\033[0;90m->\033[0m'
    if [ "_${DEFAULT}" = '_true' ]; then
      NEWLINE=" \033[${DEFAULT_COLOR}(default)\033[0m\n"
    fi
    if [ "_${VERSION}" = "_${NVM_CURRENT-}" ]; then
      ALIAS_FORMAT="\033[${CURRENT_COLOR}%s\033[0m"
      DEST_FORMAT="\033[${CURRENT_COLOR}%s\033[0m"
      VERSION_FORMAT="\033[${CURRENT_COLOR}%s\033[0m"
    elif nvm_is_version_installed "${VERSION}"; then
      ALIAS_FORMAT="\033[${INSTALLED_COLOR}%s\033[0m"
      DEST_FORMAT="\033[${INSTALLED_COLOR}%s\033[0m"
      VERSION_FORMAT="\033[${INSTALLED_COLOR}%s\033[0m"
    elif [ "${VERSION}" = '∞' ] || [ "${VERSION}" = 'N/A' ]; then
      ALIAS_FORMAT="\033[${NOT_INSTALLED_COLOR}%s\033[0m"
      DEST_FORMAT="\033[${NOT_INSTALLED_COLOR}%s\033[0m"
      VERSION_FORMAT="\033[${NOT_INSTALLED_COLOR}%s\033[0m"
    fi
    if [ "_${NVM_LTS-}" = '_true' ]; then
      ALIAS_FORMAT="\033[${LTS_COLOR}%s\033[0m"
    fi
    if [ "_${DEST%/*}" = "_lts" ]; then
      DEST_FORMAT="\033[${LTS_COLOR}%s\033[0m"
    fi
  elif [ "_${VERSION}" != '_∞' ] && [ "_${VERSION}" != '_N/A' ]; then
    VERSION_FORMAT='%s *'
  fi
  if [ "${DEST}" = "${VERSION}" ]; then
    command printf -- "${ALIAS_FORMAT} ${ARROW} ${VERSION_FORMAT}${NEWLINE}" "${ALIAS}" "${DEST}"
  else
    command printf -- "${ALIAS_FORMAT} ${ARROW} ${DEST_FORMAT} (${ARROW} ${VERSION_FORMAT})${NEWLINE}" "${ALIAS}" "${DEST}" "${VERSION}"
  fi
}

nvm_print_alias_path() {
  local NVM_ALIAS_DIR
  NVM_ALIAS_DIR="${1-}"
  if [ -z "${NVM_ALIAS_DIR}" ]; then
    nvm_err 'An alias dir is required.'
    return 1
  fi
  local ALIAS_PATH
  ALIAS_PATH="${2-}"
  if [ -z "${ALIAS_PATH}" ]; then
    nvm_err 'An alias path is required.'
    return 2
  fi
  local ALIAS
  ALIAS="${ALIAS_PATH##${NVM_ALIAS_DIR}\/}"
  local DEST
  DEST="$(nvm_alias "${ALIAS}" 2>/dev/null)" ||:
  if [ -n "${DEST}" ]; then
    NVM_NO_COLORS="${NVM_NO_COLORS-}" NVM_LTS="${NVM_LTS-}" DEFAULT=false nvm_print_formatted_alias "${ALIAS}" "${DEST}"
  fi
}

nvm_print_default_alias() {
  local ALIAS
  ALIAS="${1-}"
  if [ -z "${ALIAS}" ]; then
    nvm_err 'A default alias is required.'
    return 1
  fi
  local DEST
  DEST="$(nvm_print_implicit_alias local "${ALIAS}")"
  if [ -n "${DEST}" ]; then
    NVM_NO_COLORS="${NVM_NO_COLORS-}" DEFAULT=true nvm_print_formatted_alias "${ALIAS}" "${DEST}"
  fi
}

nvm_make_alias() {
  local ALIAS
  ALIAS="${1-}"
  if [ -z "${ALIAS}" ]; then
    nvm_err "an alias name is required"
    return 1
  fi
  local VERSION
  VERSION="${2-}"
  if [ -z "${VERSION}" ]; then
    nvm_err "an alias target version is required"
    return 2
  fi
  nvm_echo "${VERSION}" | tee "$(nvm_alias_path)/${ALIAS}" >/dev/null
}

nvm_list_aliases() {
  local ALIAS
  ALIAS="${1-}"

  local NVM_CURRENT
  NVM_CURRENT="$(nvm_ls_current)"
  local NVM_ALIAS_DIR
  NVM_ALIAS_DIR="$(nvm_alias_path)"
  command mkdir -p "${NVM_ALIAS_DIR}/lts"

  (
    local ALIAS_PATH
    for ALIAS_PATH in "${NVM_ALIAS_DIR}/${ALIAS}"*; do
      NVM_NO_COLORS="${NVM_NO_COLORS-}" NVM_CURRENT="${NVM_CURRENT}" nvm_print_alias_path "${NVM_ALIAS_DIR}" "${ALIAS_PATH}" &
    done
    wait
  ) | sort

  (
    local ALIAS_NAME
    for ALIAS_NAME in "$(nvm_node_prefix)" "stable" "unstable"; do
      {
        # shellcheck disable=SC2030,SC2031 # (https://github.com/koalaman/shellcheck/issues/2217)
        if [ ! -f "${NVM_ALIAS_DIR}/${ALIAS_NAME}" ] && { [ -z "${ALIAS}" ] || [ "${ALIAS_NAME}" = "${ALIAS}" ]; }; then
          NVM_NO_COLORS="${NVM_NO_COLORS-}" NVM_CURRENT="${NVM_CURRENT}" nvm_print_default_alias "${ALIAS_NAME}"
        fi
      } &
    done
    wait
    ALIAS_NAME="$(nvm_iojs_prefix)"
    # shellcheck disable=SC2030,SC2031 # (https://github.com/koalaman/shellcheck/issues/2217)
    if [ ! -f "${NVM_ALIAS_DIR}/${ALIAS_NAME}" ] && { [ -z "${ALIAS}" ] || [ "${ALIAS_NAME}" = "${ALIAS}" ]; }; then
      NVM_NO_COLORS="${NVM_NO_COLORS-}" NVM_CURRENT="${NVM_CURRENT}" nvm_print_default_alias "${ALIAS_NAME}"
    fi
  ) | sort

  (
    local LTS_ALIAS
    # shellcheck disable=SC2030,SC2031 # (https://github.com/koalaman/shellcheck/issues/2217)
    for ALIAS_PATH in "${NVM_ALIAS_DIR}/lts/${ALIAS}"*; do
      {
        LTS_ALIAS="$(NVM_NO_COLORS="${NVM_NO_COLORS-}" NVM_LTS=true nvm_print_alias_path "${NVM_ALIAS_DIR}" "${ALIAS_PATH}")"
        if [ -n "${LTS_ALIAS}" ]; then
          nvm_echo "${LTS_ALIAS}"
        fi
      } &
    done
    wait
  ) | sort
  return
}

nvm_alias() {
  local ALIAS
  ALIAS="${1-}"
  if [ -z "${ALIAS}" ]; then
    nvm_err 'An alias is required.'
    return 1
  fi

  local NVM_ALIAS_DIR
  NVM_ALIAS_DIR="$(nvm_alias_path)"

  if [ "$(expr "${ALIAS}" : '^lts/-[1-9][0-9]*$')" -gt 0 ]; then
    local N
    N="$(echo "${ALIAS}" | cut -d '-' -f 2)"
    N=$((N+1))
    local RESULT
    RESULT="$(command ls "${NVM_ALIAS_DIR}/lts" | command tail -n "${N}" | command head -n 1)"
    if [ "${RESULT}" != '*' ]; then
      nvm_alias "lts/${RESULT}"
      return $?
    else
      nvm_err 'That many LTS releases do not exist yet.'
      return 2
    fi
  fi

  local NVM_ALIAS_PATH
  NVM_ALIAS_PATH="${NVM_ALIAS_DIR}/${ALIAS}"
  if [ ! -f "${NVM_ALIAS_PATH}" ]; then
    nvm_err 'Alias does not exist.'
    return 2
  fi

  command cat "${NVM_ALIAS_PATH}"
}

nvm_ls_current() {
  local NVM_LS_CURRENT_NODE_PATH
  if ! NVM_LS_CURRENT_NODE_PATH="$(command which node 2>/dev/null)"; then
    nvm_echo 'none'
  elif nvm_tree_contains_path "$(nvm_version_dir iojs)" "${NVM_LS_CURRENT_NODE_PATH}"; then
    nvm_add_iojs_prefix "$(iojs --version 2>/dev/null)"
  elif nvm_tree_contains_path "${NVM_DIR}" "${NVM_LS_CURRENT_NODE_PATH}"; then
    local VERSION
    VERSION="$(node --version 2>/dev/null)"
    if [ "${VERSION}" = "v0.6.21-pre" ]; then
      nvm_echo 'v0.6.21'
    else
      nvm_echo "${VERSION}"
    fi
  else
    nvm_echo 'system'
  fi
}

nvm_resolve_alias() {
  if [ -z "${1-}" ]; then
    return 1
  fi

  local PATTERN
  PATTERN="${1-}"

  local ALIAS
  ALIAS="${PATTERN}"
  local ALIAS_TEMP

  local SEEN_ALIASES
  SEEN_ALIASES="${ALIAS}"
  while true; do
    ALIAS_TEMP="$(nvm_alias "${ALIAS}" 2>/dev/null || nvm_echo)"

    if [ -z "${ALIAS_TEMP}" ]; then
      break
    fi

    if command printf "${SEEN_ALIASES}" | nvm_grep -q -e "^${ALIAS_TEMP}$"; then
      ALIAS="∞"
      break
    fi

    SEEN_ALIASES="${SEEN_ALIASES}\\n${ALIAS_TEMP}"
    ALIAS="${ALIAS_TEMP}"
  done

  if [ -n "${ALIAS}" ] && [ "_${ALIAS}" != "_${PATTERN}" ]; then
    local NVM_IOJS_PREFIX
    NVM_IOJS_PREFIX="$(nvm_iojs_prefix)"
    local NVM_NODE_PREFIX
    NVM_NODE_PREFIX="$(nvm_node_prefix)"
    case "${ALIAS}" in
      '∞' | \
      "${NVM_IOJS_PREFIX}" | "${NVM_IOJS_PREFIX}-" | \
      "${NVM_NODE_PREFIX}")
        nvm_echo "${ALIAS}"
      ;;
      *)
        nvm_ensure_version_prefix "${ALIAS}"
      ;;
    esac
    return 0
  fi

  if nvm_validate_implicit_alias "${PATTERN}" 2>/dev/null; then
    local IMPLICIT
    IMPLICIT="$(nvm_print_implicit_alias local "${PATTERN}" 2>/dev/null)"
    if [ -n "${IMPLICIT}" ]; then
      nvm_ensure_version_prefix "${IMPLICIT}"
    fi
  fi

  return 2
}

nvm_resolve_local_alias() {
  if [ -z "${1-}" ]; then
    return 1
  fi

  local VERSION
  local EXIT_CODE
  VERSION="$(nvm_resolve_alias "${1-}")"
  EXIT_CODE=$?
  if [ -z "${VERSION}" ]; then
    return $EXIT_CODE
  fi
  if [ "_${VERSION}" != '_∞' ]; then
    nvm_version "${VERSION}"
  else
    nvm_echo "${VERSION}"
  fi
}
