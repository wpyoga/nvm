local NVM_LTS
local PATTERN
local NVM_NO_COLORS

while [ $# -gt 0 ]; do
  case "${1-}" in
    --) ;;
    --lts)
      NVM_LTS='*'
    ;;
    --lts=*)
      NVM_LTS="${1##--lts=}"
    ;;
    --no-colors) NVM_NO_COLORS="${1}" ;;
    --*)
      nvm_err "Unsupported option \"${1}\"."
      return 55
    ;;
    *)
      if [ -z "${PATTERN-}" ]; then
        PATTERN="${1-}"
        if [ -z "${NVM_LTS-}" ]; then
          case "${PATTERN}" in
            'lts/*') NVM_LTS='*' ;;
            lts/*) NVM_LTS="${PATTERN##lts/}" ;;
          esac
        fi
      fi
    ;;
  esac
  shift
done

local NVM_OUTPUT
local EXIT_CODE
NVM_OUTPUT="$(NVM_LTS="${NVM_LTS-}" nvm_remote_versions "${PATTERN}" &&:)"
EXIT_CODE=$?
if [ -n "${NVM_OUTPUT}" ]; then
  NVM_NO_COLORS="${NVM_NO_COLORS-}" nvm_print_versions "${NVM_OUTPUT}"
  return $EXIT_CODE
fi
NVM_NO_COLORS="${NVM_NO_COLORS-}" nvm_print_versions "N/A"
return 3
