local NVM_ALIAS_DIR
NVM_ALIAS_DIR="$(nvm_alias_path)"
local NVM_CURRENT
NVM_CURRENT="$(nvm_ls_current)"

command mkdir -p "${NVM_ALIAS_DIR}/lts"

local ALIAS
local TARGET
local NVM_NO_COLORS
ALIAS='--'
TARGET='--'

while [ $# -gt 0 ]; do
  case "${1-}" in
    --) ;;
    --no-colors) NVM_NO_COLORS="${1}" ;;
    --*)
      nvm_err "Unsupported option \"${1}\"."
      return 55
    ;;
    *)
      if [ "${ALIAS}" = '--' ]; then
        ALIAS="${1-}"
      elif [ "${TARGET}" = '--' ]; then
        TARGET="${1-}"
      fi
    ;;
  esac
  shift
done

if [ -z "${TARGET}" ]; then
  # for some reason the empty string was explicitly passed as the target
  # so, unalias it.
  nvm unalias "${ALIAS}"
  return $?
elif [ "${TARGET}" != '--' ]; then
  # a target was passed: create an alias
  if [ "${ALIAS#*\/}" != "${ALIAS}" ]; then
    nvm_err 'Aliases in subdirectories are not supported.'
    return 1
  fi
  VERSION="$(nvm_version "${TARGET}")" ||:
  if [ "${VERSION}" = 'N/A' ]; then
    nvm_err "! WARNING: Version '${TARGET}' does not exist."
  fi
  nvm_make_alias "${ALIAS}" "${TARGET}"
  NVM_NO_COLORS="${NVM_NO_COLORS-}" NVM_CURRENT="${NVM_CURRENT-}" DEFAULT=false nvm_print_formatted_alias "${ALIAS}" "${TARGET}" "${VERSION}"
else
  if [ "${ALIAS-}" = '--' ]; then
    unset ALIAS
  fi

  nvm_list_aliases "${ALIAS-}"
fi
