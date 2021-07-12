local NVM_ALIAS_DIR
NVM_ALIAS_DIR="$(nvm_alias_path)"
command mkdir -p "${NVM_ALIAS_DIR}"
if [ $# -ne 1 ]; then
  >&2 nvm --help
  return 127
fi
if [ "${1#*\/}" != "${1-}" ]; then
  nvm_err 'Aliases in subdirectories are not supported.'
  return 1
fi

local NVM_IOJS_PREFIX
local NVM_NODE_PREFIX
NVM_IOJS_PREFIX="$(nvm_iojs_prefix)"
NVM_NODE_PREFIX="$(nvm_node_prefix)"
local NVM_ALIAS_EXISTS
NVM_ALIAS_EXISTS=0
if [ -f "${NVM_ALIAS_DIR}/${1-}" ]; then
  NVM_ALIAS_EXISTS=1
fi

if [ $NVM_ALIAS_EXISTS -eq 0 ]; then
  case "$1" in
    "stable" | "unstable" | "${NVM_IOJS_PREFIX}" | "${NVM_NODE_PREFIX}" | "system")
      nvm_err "${1-} is a default (built-in) alias and cannot be deleted."
      return 1
    ;;
  esac

  nvm_err "Alias ${1-} doesn't exist!"
  return
fi

local NVM_ALIAS_ORIGINAL
NVM_ALIAS_ORIGINAL="$(nvm_alias "${1}")"
command rm -f "${NVM_ALIAS_DIR}/${1}"
nvm_echo "Deleted alias ${1} - restore it with \`nvm alias \"${1}\" \"${NVM_ALIAS_ORIGINAL}\"\`"
