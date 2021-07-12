local provided_version
local has_checked_nvmrc
has_checked_nvmrc=0
# run given version of node

local NVM_SILENT
local NVM_SILENT_ARG
local NVM_LTS
while [ $# -gt 0 ]; do
  case "$1" in
    --silent)
      NVM_SILENT=1
      NVM_SILENT_ARG='--silent'
      shift
    ;;
    --lts) NVM_LTS='*' ; shift ;;
    --lts=*) NVM_LTS="${1##--lts=}" ; shift ;;
    *)
      if [ -n "$1" ]; then
        break
      else
        shift
      fi
    ;; # stop processing arguments
  esac
done

if [ $# -lt 1 ] && [ -z "${NVM_LTS-}" ]; then
  NVM_SILENT="${NVM_SILENT:-0}" nvm_rc_version && has_checked_nvmrc=1
  if [ -n "${NVM_RC_VERSION-}" ]; then
    VERSION="$(nvm_version "${NVM_RC_VERSION-}")" ||:
  fi
  unset NVM_RC_VERSION
  if [ "${VERSION:-N/A}" = 'N/A' ]; then
    >&2 nvm --help
    return 127
  fi
fi

if [ -z "${NVM_LTS-}" ]; then
  provided_version="$1"
  if [ -n "${provided_version}" ]; then
    VERSION="$(nvm_version "${provided_version}")" ||:
    if [ "_${VERSION:-N/A}" = '_N/A' ] && ! nvm_is_valid_version "${provided_version}"; then
      provided_version=''
      if [ $has_checked_nvmrc -ne 1 ]; then
        NVM_SILENT="${NVM_SILENT:-0}" nvm_rc_version && has_checked_nvmrc=1
      fi
      VERSION="$(nvm_version "${NVM_RC_VERSION}")" ||:
      unset NVM_RC_VERSION
    else
      shift
    fi
  fi
fi

local NVM_IOJS
if nvm_is_iojs_version "${VERSION}"; then
  NVM_IOJS=true
fi

local EXIT_CODE

nvm_is_zsh && setopt local_options shwordsplit
local LTS_ARG
if [ -n "${NVM_LTS-}" ]; then
  LTS_ARG="--lts=${NVM_LTS-}"
  VERSION=''
fi
if [ "_${VERSION}" = "_N/A" ]; then
  nvm_ensure_version_installed "${provided_version}"
elif [ "${NVM_IOJS}" = true ]; then
  nvm exec "${NVM_SILENT_ARG-}" "${LTS_ARG-}" "${VERSION}" iojs "$@"
else
  nvm exec "${NVM_SILENT_ARG-}" "${LTS_ARG-}" "${VERSION}" node "$@"
fi
EXIT_CODE="$?"
return $EXIT_CODE
