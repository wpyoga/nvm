nvm_is_iojs_version() {
  case "${1-}" in iojs-*) return 0 ;; esac
  return 1
}

nvm_add_iojs_prefix() {
  nvm_echo "$(nvm_iojs_prefix)-$(nvm_ensure_version_prefix "$(nvm_strip_iojs_prefix "${1-}")")"
}

nvm_strip_iojs_prefix() {
  local NVM_IOJS_PREFIX
  NVM_IOJS_PREFIX="$(nvm_iojs_prefix)"
  if [ "${1-}" = "${NVM_IOJS_PREFIX}" ]; then
    nvm_echo
  else
    nvm_echo "${1#${NVM_IOJS_PREFIX}-}"
  fi
}
