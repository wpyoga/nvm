local PROVIDED_VERSION
local NVM_SILENT
local NVM_SILENT_ARG
local NVM_DELETE_PREFIX
NVM_DELETE_PREFIX=0
local NVM_LTS

while [ $# -ne 0 ]; do
  case "$1" in
    --silent)
      NVM_SILENT=1
      NVM_SILENT_ARG='--silent'
    ;;
    --delete-prefix) NVM_DELETE_PREFIX=1 ;;
    --) ;;
    --lts) NVM_LTS='*' ;;
    --lts=*) NVM_LTS="${1##--lts=}" ;;
    --*) ;;
    *)
      if [ -n "${1-}" ]; then
        PROVIDED_VERSION="$1"
      fi
    ;;
  esac
  shift
done

if [ -n "${NVM_LTS-}" ]; then
  VERSION="$(nvm_match_version "lts/${NVM_LTS:-*}")"
elif [ -z "${PROVIDED_VERSION-}" ]; then
  NVM_SILENT="${NVM_SILENT:-0}" nvm_rc_version
  if [ -n "${NVM_RC_VERSION-}" ]; then
    PROVIDED_VERSION="${NVM_RC_VERSION}"
    VERSION="$(nvm_version "${PROVIDED_VERSION}")"
  fi
  unset NVM_RC_VERSION
  if [ -z "${VERSION}" ]; then
    nvm_err 'Please see `nvm --help` or https://github.com/nvm-sh/nvm#nvmrc for more information.'
    return 127
  fi
else
  VERSION="$(nvm_match_version "${PROVIDED_VERSION}")"
fi

if [ -z "${VERSION}" ]; then
  >&2 nvm --help
  return 127
fi

if [ "_${VERSION}" = '_system' ]; then
  if nvm_has_system_node && nvm deactivate "${NVM_SILENT_ARG-}" >/dev/null 2>&1; then
    if [ "${NVM_SILENT:-0}" -ne 1 ]; then
      nvm_echo "Now using system version of node: $(node -v 2>/dev/null)$(nvm_print_npm_version)"
    fi
    return
  elif nvm_has_system_iojs && nvm deactivate "${NVM_SILENT_ARG-}" >/dev/null 2>&1; then
    if [ "${NVM_SILENT:-0}" -ne 1 ]; then
      nvm_echo "Now using system version of io.js: $(iojs --version 2>/dev/null)$(nvm_print_npm_version)"
    fi
    return
  elif [ "${NVM_SILENT:-0}" -ne 1 ]; then
    nvm_err 'System version of node not found.'
  fi
  return 127
elif [ "_${VERSION}" = "_∞" ]; then
  if [ "${NVM_SILENT:-0}" -ne 1 ]; then
    nvm_err "The alias \"${PROVIDED_VERSION}\" leads to an infinite loop. Aborting."
  fi
  return 8
fi
if [ "${VERSION}" = 'N/A' ]; then
  if [ "${NVM_SILENT:-0}" -ne 1 ]; then
    nvm_err "N/A: version \"${PROVIDED_VERSION} -> ${VERSION}\" is not yet installed."
    nvm_err ""
    nvm_err "You need to run \"nvm install ${PROVIDED_VERSION}\" to install it before using it."
  fi
  return 3
# This nvm_ensure_version_installed call can be a performance bottleneck
# on shell startup. Perhaps we can optimize it away or make it faster.
elif ! nvm_ensure_version_installed "${VERSION}"; then
  return $?
fi

local NVM_VERSION_DIR
NVM_VERSION_DIR="$(nvm_version_path "${VERSION}")"

# Change current version
PATH="$(nvm_change_path "${PATH}" "/bin" "${NVM_VERSION_DIR}")"
if nvm_has manpath; then
  if [ -z "${MANPATH-}" ]; then
    local MANPATH
    MANPATH=$(manpath)
  fi
  # Change current version
  MANPATH="$(nvm_change_path "${MANPATH}" "/share/man" "${NVM_VERSION_DIR}")"
  export MANPATH
fi
export PATH
hash -r
export NVM_BIN="${NVM_VERSION_DIR}/bin"
export NVM_INC="${NVM_VERSION_DIR}/include/node"
if [ "${NVM_SYMLINK_CURRENT-}" = true ]; then
  command rm -f "${NVM_DIR}/current" && ln -s "${NVM_VERSION_DIR}" "${NVM_DIR}/current"
fi
local NVM_USE_OUTPUT
NVM_USE_OUTPUT=''
if [ "${NVM_SILENT:-0}" -ne 1 ]; then
  if nvm_is_iojs_version "${VERSION}"; then
    NVM_USE_OUTPUT="Now using io.js $(nvm_strip_iojs_prefix "${VERSION}")$(nvm_print_npm_version)"
  else
    NVM_USE_OUTPUT="Now using node ${VERSION}$(nvm_print_npm_version)"
  fi
fi
if [ "_${VERSION}" != "_system" ]; then
  local NVM_USE_CMD
  NVM_USE_CMD="nvm use --delete-prefix"
  if [ -n "${PROVIDED_VERSION}" ]; then
    NVM_USE_CMD="${NVM_USE_CMD} ${VERSION}"
  fi
  if [ "${NVM_SILENT:-0}" -eq 1 ]; then
    NVM_USE_CMD="${NVM_USE_CMD} --silent"
  fi
  if ! nvm_die_on_prefix "${NVM_DELETE_PREFIX}" "${NVM_USE_CMD}" "${NVM_VERSION_DIR}"; then
    return 11
  fi
fi
if [ -n "${NVM_USE_OUTPUT-}" ] && [ "${NVM_SILENT:-0}" -ne 1 ]; then
  nvm_echo "${NVM_USE_OUTPUT}"
fi
