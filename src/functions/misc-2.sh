nvm_ensure_default_set() {
  local VERSION
  VERSION="$1"
  if [ -z "${VERSION}" ]; then
    nvm_err 'nvm_ensure_default_set: a version is required'
    return 1
  elif nvm_alias default >/dev/null 2>&1; then
    # default already set
    return 0
  fi
  local OUTPUT
  OUTPUT="$(nvm alias default "${VERSION}")"
  local EXIT_CODE
  EXIT_CODE="$?"
  nvm_echo "Creating default alias: ${OUTPUT}"
  return $EXIT_CODE
}

nvm_is_merged_node_version() {
  nvm_version_greater_than_or_equal_to "$1" v4.0.0
}
