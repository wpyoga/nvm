local PATTERN
local NVM_NO_COLORS
local NVM_NO_ALIAS

while [ $# -gt 0 ]; do
  case "${1}" in
    --) ;;
    --no-colors) NVM_NO_COLORS="${1}" ;;
    --no-alias) NVM_NO_ALIAS="${1}" ;;
    --*)
      nvm_err "Unsupported option \"${1}\"."
      return 55
    ;;
    *)
      PATTERN="${PATTERN:-$1}"
    ;;
  esac
  shift
done
if [ -n "${PATTERN-}" ] && [ -n "${NVM_NO_ALIAS-}" ]; then
  nvm_err '`--no-alias` is not supported when a pattern is provided.'
  return 55
fi
local NVM_LS_OUTPUT
local NVM_LS_EXIT_CODE
NVM_LS_OUTPUT=$(nvm_ls "${PATTERN-}")
NVM_LS_EXIT_CODE=$?
NVM_NO_COLORS="${NVM_NO_COLORS-}" nvm_print_versions "${NVM_LS_OUTPUT}"
if [ -z "${NVM_NO_ALIAS-}" ] && [ -z "${PATTERN-}" ]; then
  if [ -n "${NVM_NO_COLORS-}" ]; then
    nvm alias --no-colors
  else
    nvm alias
  fi
fi
return $NVM_LS_EXIT_CODE
