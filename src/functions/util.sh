nvm_is_zsh() {
  [ -n "${ZSH_VERSION-}" ]
}

nvm_stdout_is_terminal() {
  [ -t 1 ]
}

nvm_echo() {
  command printf %s\\n "$*" 2>/dev/null
}

nvm_echo_with_colors() {
  command printf %b\\n "$*" 2>/dev/null
}

nvm_cd() {
  \cd "$@"
}

nvm_err() {
  >&2 nvm_echo "$@"
}

nvm_err_with_colors() {
  >&2 nvm_echo_with_colors "$@"
}

nvm_grep() {
  GREP_OPTIONS='' command grep "$@"
}

nvm_has() {
  type "${1-}" >/dev/null 2>&1
}

nvm_has_non_aliased() {
  nvm_has "${1-}" && ! nvm_is_alias "${1-}"
}

nvm_is_alias() {
  # this is intentionally not "command alias" so it works in zsh.
  \alias "${1-}" >/dev/null 2>&1
}

nvm_command_info() {
  local COMMAND
  local INFO
  COMMAND="${1}"
  if type "${COMMAND}" | nvm_grep -q hashed; then
    INFO="$(type "${COMMAND}" | command sed -E 's/\(|\)//g' | command awk '{print $4}')"
  elif type "${COMMAND}" | nvm_grep -q aliased; then
    # shellcheck disable=SC2230
    INFO="$(which "${COMMAND}") ($(type "${COMMAND}" | command awk '{ $1=$2=$3=$4="" ;print }' | command sed -e 's/^\ *//g' -Ee "s/\`|'//g"))"
  elif type "${COMMAND}" | nvm_grep -q "^${COMMAND} is an alias for"; then
    # shellcheck disable=SC2230
    INFO="$(which "${COMMAND}") ($(type "${COMMAND}" | command awk '{ $1=$2=$3=$4=$5="" ;print }' | command sed 's/^\ *//g'))"
  elif type "${COMMAND}" | nvm_grep -q "^${COMMAND} is \\/"; then
    INFO="$(type "${COMMAND}" | command awk '{print $3}')"
  else
    INFO="$(type "${COMMAND}")"
  fi
  nvm_echo "${INFO}"
}

nvm_has_colors() {
  local NVM_NUM_COLORS
  if nvm_has tput; then
    NVM_NUM_COLORS="$(tput -T "${TERM:-vt100}" colors)"
  fi
  [ "${NVM_NUM_COLORS:--1}" -ge 8 ]
}

nvm_curl_libz_support() {
  curl -V 2>/dev/null | nvm_grep "^Features:" | nvm_grep -q "libz"
}

nvm_curl_use_compression() {
  nvm_curl_libz_support && nvm_version_greater_than_or_equal_to "$(nvm_curl_version)" 7.21.0
}
