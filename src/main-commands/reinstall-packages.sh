if [ $# -ne 1 ]; then
  >&2 nvm --help
  return 127
fi

local PROVIDED_VERSION
PROVIDED_VERSION="${1-}"

if [ "${PROVIDED_VERSION}" = "$(nvm_ls_current)" ] || [ "$(nvm_version "${PROVIDED_VERSION}" ||:)" = "$(nvm_ls_current)" ]; then
  nvm_err 'Can not reinstall packages from the current version of node.'
  return 2
fi

local VERSION
if [ "_${PROVIDED_VERSION}" = "_system" ]; then
  if ! nvm_has_system_node && ! nvm_has_system_iojs; then
    nvm_err 'No system version of node or io.js detected.'
    return 3
  fi
  VERSION="system"
else
  VERSION="$(nvm_version "${PROVIDED_VERSION}")" ||:
fi

local NPMLIST
NPMLIST="$(nvm_npm_global_modules "${VERSION}")"
local INSTALLS
local LINKS
INSTALLS="${NPMLIST%% //// *}"
LINKS="${NPMLIST##* //// }"

nvm_echo "Reinstalling global packages from ${VERSION}..."
if [ -n "${INSTALLS}" ]; then
  nvm_echo "${INSTALLS}" | command xargs npm install -g --quiet
else
  nvm_echo "No installed global packages found..."
fi

nvm_echo "Linking global packages from ${VERSION}..."
if [ -n "${LINKS}" ]; then
  (
    # @MULTILINE
    set -f; IFS='
' # necessary to turn off variable expansion except for newlines
    # @MULTILINE-END
    for LINK in ${LINKS}; do
      set +f; unset IFS # restore variable expansion
      if [ -n "${LINK}" ]; then
        (nvm_cd "${LINK}" && npm link)
      fi
    done
  )
else
  nvm_echo "No linked global packages found..."
fi
