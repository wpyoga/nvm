local NVM_SILENT
local NVM_LTS
while [ $# -gt 0 ]; do
  case "$1" in
    --silent) NVM_SILENT=1 ; shift ;;
    --lts) NVM_LTS='*' ; shift ;;
    --lts=*) NVM_LTS="${1##--lts=}" ; shift ;;
    --) break ;;
    --*)
      nvm_err "Unsupported option \"$1\"."
      return 55
    ;;
    *)
      if [ -n "$1" ]; then
        break
      else
        shift
      fi
    ;; # stop processing arguments
  esac
done

local provided_version
provided_version="$1"
if [ "${NVM_LTS-}" != '' ]; then
  provided_version="lts/${NVM_LTS:-*}"
  VERSION="${provided_version}"
elif [ -n "${provided_version}" ]; then
  VERSION="$(nvm_version "${provided_version}")" ||:
  if [ "_${VERSION}" = '_N/A' ] && ! nvm_is_valid_version "${provided_version}"; then
    NVM_SILENT="${NVM_SILENT:-0}" nvm_rc_version && has_checked_nvmrc=1
    provided_version="${NVM_RC_VERSION}"
    unset NVM_RC_VERSION
    VERSION="$(nvm_version "${provided_version}")" ||:
  else
    shift
  fi
fi

nvm_ensure_version_installed "${provided_version}"
EXIT_CODE=$?
if [ "${EXIT_CODE}" != "0" ]; then
  return $EXIT_CODE
fi

if [ "${NVM_SILENT:-0}" -ne 1 ]; then
  if [ "${NVM_LTS-}" = '*' ]; then
    nvm_echo "Running node latest LTS -> $(nvm_version "${VERSION}")$(nvm use --silent "${VERSION}" && nvm_print_npm_version)"
  elif [ -n "${NVM_LTS-}" ]; then
    nvm_echo "Running node LTS \"${NVM_LTS-}\" -> $(nvm_version "${VERSION}")$(nvm use --silent "${VERSION}" && nvm_print_npm_version)"
  elif nvm_is_iojs_version "${VERSION}"; then
    nvm_echo "Running io.js $(nvm_strip_iojs_prefix "${VERSION}")$(nvm use --silent "${VERSION}" && nvm_print_npm_version)"
  else
    nvm_echo "Running node ${VERSION}$(nvm use --silent "${VERSION}" && nvm_print_npm_version)"
  fi
fi
NODE_VERSION="${VERSION}" "${NVM_DIR}/nvm-exec" "$@"
