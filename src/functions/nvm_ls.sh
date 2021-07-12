nvm_ls() {
  local PATTERN
  PATTERN="${1-}"
  local VERSIONS
  VERSIONS=''
  if [ "${PATTERN}" = 'current' ]; then
    nvm_ls_current
    return
  fi

  local NVM_IOJS_PREFIX
  NVM_IOJS_PREFIX="$(nvm_iojs_prefix)"
  local NVM_NODE_PREFIX
  NVM_NODE_PREFIX="$(nvm_node_prefix)"
  local NVM_VERSION_DIR_IOJS
  NVM_VERSION_DIR_IOJS="$(nvm_version_dir "${NVM_IOJS_PREFIX}")"
  local NVM_VERSION_DIR_NEW
  NVM_VERSION_DIR_NEW="$(nvm_version_dir new)"
  local NVM_VERSION_DIR_OLD
  NVM_VERSION_DIR_OLD="$(nvm_version_dir old)"

  case "${PATTERN}" in
    "${NVM_IOJS_PREFIX}" | "${NVM_NODE_PREFIX}")
      PATTERN="${PATTERN}-"
    ;;
    *)
      if nvm_resolve_local_alias "${PATTERN}"; then
        return
      fi
      PATTERN="$(nvm_ensure_version_prefix "${PATTERN}")"
    ;;
  esac
  if [ "${PATTERN}" = 'N/A' ]; then
    return
  fi
  # If it looks like an explicit version, don't do anything funny
  local NVM_PATTERN_STARTS_WITH_V
  case $PATTERN in
    v*) NVM_PATTERN_STARTS_WITH_V=true ;;
    *) NVM_PATTERN_STARTS_WITH_V=false ;;
  esac
  if [ $NVM_PATTERN_STARTS_WITH_V = true ] && [ "_$(nvm_num_version_groups "${PATTERN}")" = "_3" ]; then
    if nvm_is_version_installed "${PATTERN}"; then
      VERSIONS="${PATTERN}"
    elif nvm_is_version_installed "$(nvm_add_iojs_prefix "${PATTERN}")"; then
      VERSIONS="$(nvm_add_iojs_prefix "${PATTERN}")"
    fi
  else
    case "${PATTERN}" in
      "${NVM_IOJS_PREFIX}-" | "${NVM_NODE_PREFIX}-" | "system") ;;
      *)
        local NUM_VERSION_GROUPS
        NUM_VERSION_GROUPS="$(nvm_num_version_groups "${PATTERN}")"
        if [ "${NUM_VERSION_GROUPS}" = "2" ] || [ "${NUM_VERSION_GROUPS}" = "1" ]; then
          PATTERN="${PATTERN%.}."
        fi
      ;;
    esac

    nvm_is_zsh && setopt local_options shwordsplit
    nvm_is_zsh && unsetopt local_options markdirs

    local NVM_DIRS_TO_SEARCH1
    NVM_DIRS_TO_SEARCH1=''
    local NVM_DIRS_TO_SEARCH2
    NVM_DIRS_TO_SEARCH2=''
    local NVM_DIRS_TO_SEARCH3
    NVM_DIRS_TO_SEARCH3=''
    local NVM_ADD_SYSTEM
    NVM_ADD_SYSTEM=false
    if nvm_is_iojs_version "${PATTERN}"; then
      NVM_DIRS_TO_SEARCH1="${NVM_VERSION_DIR_IOJS}"
      PATTERN="$(nvm_strip_iojs_prefix "${PATTERN}")"
      if nvm_has_system_iojs; then
        NVM_ADD_SYSTEM=true
      fi
    elif [ "${PATTERN}" = "${NVM_NODE_PREFIX}-" ]; then
      NVM_DIRS_TO_SEARCH1="${NVM_VERSION_DIR_OLD}"
      NVM_DIRS_TO_SEARCH2="${NVM_VERSION_DIR_NEW}"
      PATTERN=''
      if nvm_has_system_node; then
        NVM_ADD_SYSTEM=true
      fi
    else
      NVM_DIRS_TO_SEARCH1="${NVM_VERSION_DIR_OLD}"
      NVM_DIRS_TO_SEARCH2="${NVM_VERSION_DIR_NEW}"
      NVM_DIRS_TO_SEARCH3="${NVM_VERSION_DIR_IOJS}"
      if nvm_has_system_iojs || nvm_has_system_node; then
        NVM_ADD_SYSTEM=true
      fi
    fi

    if ! [ -d "${NVM_DIRS_TO_SEARCH1}" ] || ! (command ls -1qA "${NVM_DIRS_TO_SEARCH1}" | nvm_grep -q .); then
      NVM_DIRS_TO_SEARCH1=''
    fi
    if ! [ -d "${NVM_DIRS_TO_SEARCH2}" ] || ! (command ls -1qA "${NVM_DIRS_TO_SEARCH2}" | nvm_grep -q .); then
      NVM_DIRS_TO_SEARCH2="${NVM_DIRS_TO_SEARCH1}"
    fi
    if ! [ -d "${NVM_DIRS_TO_SEARCH3}" ] || ! (command ls -1qA "${NVM_DIRS_TO_SEARCH3}" | nvm_grep -q .); then
      NVM_DIRS_TO_SEARCH3="${NVM_DIRS_TO_SEARCH2}"
    fi

    local SEARCH_PATTERN
    if [ -z "${PATTERN}" ]; then
      PATTERN='v'
      SEARCH_PATTERN='.*'
    else
      SEARCH_PATTERN="$(nvm_echo "${PATTERN}" | command sed 's#\.#\\\.#g;')"
    fi
    if [ -n "${NVM_DIRS_TO_SEARCH1}${NVM_DIRS_TO_SEARCH2}${NVM_DIRS_TO_SEARCH3}" ]; then
      VERSIONS="$(command find "${NVM_DIRS_TO_SEARCH1}"/* "${NVM_DIRS_TO_SEARCH2}"/* "${NVM_DIRS_TO_SEARCH3}"/* -name . -o -type d -prune -o -path "${PATTERN}*" \
        | command sed -e "
            s#${NVM_VERSION_DIR_IOJS}/#versions/${NVM_IOJS_PREFIX}/#;
            s#^${NVM_DIR}/##;
            \\#^[^v]# d;
            \\#^versions\$# d;
            s#^versions/##;
            s#^v#${NVM_NODE_PREFIX}/v#;
            \\#${SEARCH_PATTERN}# !d;
          " \
          -e 's#^\([^/]\{1,\}\)/\(.*\)$#\2.\1#;' \
        | command sort -t. -u -k 1.2,1n -k 2,2n -k 3,3n \
        | command sed -e 's#\(.*\)\.\([^\.]\{1,\}\)$#\2-\1#;' \
                      -e "s#^${NVM_NODE_PREFIX}-##;" \
      )"
    fi
  fi

  if [ "${NVM_ADD_SYSTEM-}" = true ]; then
    if [ -z "${PATTERN}" ] || [ "${PATTERN}" = 'v' ]; then
      VERSIONS="${VERSIONS}$(command printf '\n%s' 'system')"
    elif [ "${PATTERN}" = 'system' ]; then
      VERSIONS="$(command printf '%s' 'system')"
    fi
  fi

  if [ -z "${VERSIONS}" ]; then
    nvm_echo 'N/A'
    return 3
  fi

  nvm_echo "${VERSIONS}"
}
