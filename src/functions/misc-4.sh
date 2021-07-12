nvm_sanitize_path() {
  local SANITIZED_PATH
  SANITIZED_PATH="${1-}"
  if [ "_${SANITIZED_PATH}" != "_${NVM_DIR}" ]; then
    SANITIZED_PATH="$(nvm_echo "${SANITIZED_PATH}" | command sed -e "s#${NVM_DIR}#\${NVM_DIR}#g")"
  fi
  if [ "_${SANITIZED_PATH}" != "_${HOME}" ]; then
    SANITIZED_PATH="$(nvm_echo "${SANITIZED_PATH}" | command sed -e "s#${HOME}#\${HOME}#g")"
  fi
  nvm_echo "${SANITIZED_PATH}"
}

nvm_is_natural_num() {
  if [ -z "$1" ]; then
    return 4
  fi
  case "$1" in
    0) return 1 ;;
    -*) return 3 ;; # some BSDs return false positives for double-negated args
    *)
      [ "$1" -eq "$1" ] 2>/dev/null # returns 2 if it doesn't match
    ;;
  esac
}

# Check version dir permissions
nvm_check_file_permissions() {
  nvm_is_zsh && setopt local_options nonomatch
  for FILE in "$1"/* "$1"/.[!.]* "$1"/..?* ; do
    if [ -d "$FILE" ]; then
      if [ -n "${NVM_DEBUG-}" ]; then
        nvm_err "${FILE}"
      fi
      if ! nvm_check_file_permissions "${FILE}"; then
        return 2
      fi
    elif [ -e "$FILE" ] && [ ! -w "$FILE" ] && [ ! -O "$FILE" ]; then
      nvm_err "file is not writable or self-owned: $(nvm_sanitize_path "$FILE")"
      return 1
    fi
  done
  return 0
}

nvm_cache_dir() {
  nvm_echo "${NVM_DIR}/.cache"
}
