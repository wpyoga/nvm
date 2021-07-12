nvm_supports_xz() {
  if [ -z "${1-}" ]; then
    return 1
  fi

  local NVM_OS
  NVM_OS="$(nvm_get_os)"
  if [ "_${NVM_OS}" = '_darwin' ]; then
    local MACOS_VERSION
    MACOS_VERSION="$(sw_vers -productVersion)"
    if nvm_version_greater "10.9.0" "${MACOS_VERSION}"; then
      # macOS 10.8 and earlier doesn't support extracting xz-compressed tarballs with tar
      return 1
    fi
  elif [ "_${NVM_OS}" = '_freebsd' ]; then
    if ! [ -e '/usr/lib/liblzma.so' ]; then
      # FreeBSD without /usr/lib/liblzma.so doesn't support extracting xz-compressed tarballs with tar
      return 1
    fi
  else
    if ! command which xz >/dev/null 2>&1; then
      # Most OSes without xz on the PATH don't support extracting xz-compressed tarballs with tar
      # (Should correctly handle Linux, SmartOS, maybe more)
      return 1
    fi
  fi

  # all node versions v4.0.0 and later have xz
  if nvm_is_merged_node_version "${1}"; then
    return 0
  fi

  # 0.12x: node v0.12.10 and later have xz
  if nvm_version_greater_than_or_equal_to "${1}" "0.12.10" && nvm_version_greater "0.13.0" "${1}"; then
    return 0
  fi

  # 0.10x: node v0.10.42 and later have xz
  if nvm_version_greater_than_or_equal_to "${1}" "0.10.42" && nvm_version_greater "0.11.0" "${1}"; then
    return 0
  fi

  case "${NVM_OS}" in
    darwin)
      # darwin only has xz for io.js v2.3.2 and later
      nvm_version_greater_than_or_equal_to "${1}" "2.3.2"
    ;;
    *)
      nvm_version_greater_than_or_equal_to "${1}" "1.0.0"
    ;;
  esac
  return $?
}

nvm_auto() {
  local NVM_MODE
  NVM_MODE="${1-}"
  local VERSION
  local NVM_CURRENT
  if [ "_${NVM_MODE}" = '_install' ]; then
    VERSION="$(nvm_alias default 2>/dev/null || nvm_echo)"
    if [ -n "${VERSION}" ]; then
      nvm install "${VERSION}" >/dev/null
    elif nvm_rc_version >/dev/null 2>&1; then
      nvm install >/dev/null
    fi
  elif [ "_$NVM_MODE" = '_use' ]; then
    NVM_CURRENT="$(nvm_ls_current)"
    if [ "_${NVM_CURRENT}" = '_none' ] || [ "_${NVM_CURRENT}" = '_system' ]; then
      VERSION="$(nvm_resolve_local_alias default 2>/dev/null || nvm_echo)"
      if [ -n "${VERSION}" ]; then
        nvm use --silent "${VERSION}" >/dev/null
      elif nvm_rc_version >/dev/null 2>&1; then
        nvm use --silent >/dev/null
      fi
    else
      nvm use --silent "${NVM_CURRENT}" >/dev/null
    fi
  elif [ "_${NVM_MODE}" != '_none' ]; then
    nvm_err 'Invalid auto mode supplied.'
    return 1
  fi
}

nvm_process_parameters() {
  local NVM_AUTO_MODE
  NVM_AUTO_MODE='use'
  while [ $# -ne 0 ]; do
    case "$1" in
      --install) NVM_AUTO_MODE='install' ;;
      --no-use) NVM_AUTO_MODE='none' ;;
    esac
    shift
  done
  nvm_auto "${NVM_AUTO_MODE}"
}
