local NVM_SILENT
while [ $# -ne 0 ]; do
  case "${1}" in
    --silent) NVM_SILENT=1 ;;
    --) ;;
  esac
  shift
done
local NEWPATH
NEWPATH="$(nvm_strip_path "${PATH}" "/bin")"
if [ "_${PATH}" = "_${NEWPATH}" ]; then
  if [ "${NVM_SILENT:-0}" -ne 1 ]; then
    nvm_err "Could not find ${NVM_DIR}/*/bin in \${PATH}"
  fi
else
  export PATH="${NEWPATH}"
  hash -r
  if [ "${NVM_SILENT:-0}" -ne 1 ]; then
    nvm_echo "${NVM_DIR}/*/bin removed from \${PATH}"
  fi
fi

if [ -n "${MANPATH-}" ]; then
  NEWPATH="$(nvm_strip_path "${MANPATH}" "/share/man")"
  if [ "_${MANPATH}" = "_${NEWPATH}" ]; then
    if [ "${NVM_SILENT:-0}" -ne 1 ]; then
      nvm_err "Could not find ${NVM_DIR}/*/share/man in \${MANPATH}"
    fi
  else
    export MANPATH="${NEWPATH}"
    if [ "${NVM_SILENT:-0}" -ne 1 ]; then
      nvm_echo "${NVM_DIR}/*/share/man removed from \${MANPATH}"
    fi
  fi
fi

if [ -n "${NODE_PATH-}" ]; then
  NEWPATH="$(nvm_strip_path "${NODE_PATH}" "/lib/node_modules")"
  if [ "_${NODE_PATH}" != "_${NEWPATH}" ]; then
    export NODE_PATH="${NEWPATH}"
    if [ "${NVM_SILENT:-0}" -ne 1 ]; then
      nvm_echo "${NVM_DIR}/*/lib/node_modules removed from \${NODE_PATH}"
    fi
  fi
fi
unset NVM_BIN
unset NVM_INC
