local NVM_SILENT
local provided_version
while [ $# -ne 0 ]; do
  case "${1}" in
    --silent) NVM_SILENT=1 ;;
    --) ;;
    *) provided_version="${1-}" ;;
  esac
  shift
done
if [ -z "${provided_version-}" ]; then
  NVM_SILENT="${NVM_SILENT:-0}" nvm_rc_version
  if [ -n "${NVM_RC_VERSION}" ]; then
    provided_version="${NVM_RC_VERSION}"
    VERSION=$(nvm_version "${NVM_RC_VERSION}") ||:
  fi
  unset NVM_RC_VERSION
elif [ "${provided_version}" != 'system' ]; then
  VERSION="$(nvm_version "${provided_version}")" ||:
else
  VERSION="${provided_version-}"
fi
if [ -z "${VERSION}" ]; then
  >&2 nvm --help
  return 127
fi

if [ "_${VERSION}" = '_system' ]; then
  if nvm_has_system_iojs >/dev/null 2>&1 || nvm_has_system_node >/dev/null 2>&1; then
    local NVM_BIN
    NVM_BIN="$(nvm use system >/dev/null 2>&1 && command which node)"
    if [ -n "${NVM_BIN}" ]; then
      nvm_echo "${NVM_BIN}"
      return
    fi
    return 1
  fi
  nvm_err 'System version of node not found.'
  return 127
elif [ "${VERSION}" = '∞' ]; then
  nvm_err "The alias \"${2}\" leads to an infinite loop. Aborting."
  return 8
fi

nvm_ensure_version_installed "${provided_version}"
EXIT_CODE=$?
if [ "${EXIT_CODE}" != "0" ]; then
  return $EXIT_CODE
fi
local NVM_VERSION_DIR
NVM_VERSION_DIR="$(nvm_version_path "${VERSION}")"
nvm_echo "${NVM_VERSION_DIR}/bin/node"
