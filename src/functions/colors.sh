nvm_set_colors() {
  if [ "${#1}" -eq 5 ] && nvm_echo "$1" | nvm_grep -E "^[rRgGbBcCyYmMkKeW]{1,}$" 1>/dev/null; then
    local INSTALLED_COLOR
    local LTS_AND_SYSTEM_COLOR
    local CURRENT_COLOR
    local NOT_INSTALLED_COLOR
    local DEFAULT_COLOR

    INSTALLED_COLOR="$(echo "$1" | awk '{ print substr($0, 1, 1); }')"
    LTS_AND_SYSTEM_COLOR="$(echo "$1" | awk '{ print substr($0, 2, 1); }')"
    CURRENT_COLOR="$(echo "$1" | awk '{ print substr($0, 3, 1); }')"
    NOT_INSTALLED_COLOR="$(echo "$1" | awk '{ print substr($0, 4, 1); }')"
    DEFAULT_COLOR="$(echo "$1" | awk '{ print substr($0, 5, 1); }')"
    if ! nvm_has_colors; then
      nvm_echo "Setting colors to: ${INSTALLED_COLOR} ${LTS_AND_SYSTEM_COLOR} ${CURRENT_COLOR} ${NOT_INSTALLED_COLOR} ${DEFAULT_COLOR}"
      nvm_echo "WARNING: Colors may not display because they are not supported in this shell."
    else
      nvm_echo_with_colors "Setting colors to: \033[$(nvm_print_color_code "${INSTALLED_COLOR}") ${INSTALLED_COLOR}\033[$(nvm_print_color_code "${LTS_AND_SYSTEM_COLOR}") ${LTS_AND_SYSTEM_COLOR}\033[$(nvm_print_color_code "${CURRENT_COLOR}") ${CURRENT_COLOR}\033[$(nvm_print_color_code "${NOT_INSTALLED_COLOR}") ${NOT_INSTALLED_COLOR}\033[$(nvm_print_color_code "${DEFAULT_COLOR}") ${DEFAULT_COLOR}\033[0m"
    fi
    export NVM_COLORS="$1"
  else
    return 17
  fi
}

nvm_get_colors() {
  local COLOR
  local SYS_COLOR
  if [ -n "${NVM_COLORS-}" ]; then
    case $1 in
      1) COLOR=$(nvm_print_color_code "$(echo "$NVM_COLORS" | awk '{ print substr($0, 1, 1); }')");;
      2) COLOR=$(nvm_print_color_code "$(echo "$NVM_COLORS" | awk '{ print substr($0, 2, 1); }')");;
      3) COLOR=$(nvm_print_color_code "$(echo "$NVM_COLORS" | awk '{ print substr($0, 3, 1); }')");;
      4) COLOR=$(nvm_print_color_code "$(echo "$NVM_COLORS" | awk '{ print substr($0, 4, 1); }')");;
      5) COLOR=$(nvm_print_color_code "$(echo "$NVM_COLORS" | awk '{ print substr($0, 5, 1); }')");;
      6)
        SYS_COLOR=$(nvm_print_color_code "$(echo "$NVM_COLORS" | awk '{ print substr($0, 2, 1); }')")
        COLOR=$(nvm_echo "$SYS_COLOR" | command tr '0;' '1;')
        ;;
      *)
        nvm_err "Invalid color index, ${1-}"
        return 1
      ;;
    esac
  else
    case $1 in
      1) COLOR='0;34m';;
      2) COLOR='0;33m';;
      3) COLOR='0;32m';;
      4) COLOR='0;31m';;
      5) COLOR='0;37m';;
      6) COLOR='1;33m';;
      *)
        nvm_err "Invalid color index, ${1-}"
        return 1
      ;;
    esac
  fi

  echo "$COLOR"
}

nvm_print_color_code() {
  case "${1-}" in
    'r') nvm_echo '0;31m';;
    'R') nvm_echo '1;31m';;
    'g') nvm_echo '0;32m';;
    'G') nvm_echo '1;32m';;
    'b') nvm_echo '0;34m';;
    'B') nvm_echo '1;34m';;
    'c') nvm_echo '0;36m';;
    'C') nvm_echo '1;36m';;
    'm') nvm_echo '0;35m';;
    'M') nvm_echo '1;35m';;
    'y') nvm_echo '0;33m';;
    'Y') nvm_echo '1;33m';;
    'k') nvm_echo '0;30m';;
    'K') nvm_echo '1;30m';;
    'e') nvm_echo '0;37m';;
    'W') nvm_echo '1;37m';;
    *) nvm_err 'Invalid color code';
        return 1
    ;;
  esac
}
