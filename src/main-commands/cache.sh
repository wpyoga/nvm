case "${1-}" in
  dir) nvm_cache_dir ;;
  clear)
    local DIR
    DIR="$(nvm_cache_dir)"
    if command rm -rf "${DIR}" && command mkdir -p "${DIR}"; then
      nvm_echo 'nvm cache cleared.'
    else
      nvm_err "Unable to clear nvm cache: ${DIR}"
      return 1
    fi
  ;;
  *)
    >&2 nvm --help
    return 127
  ;;
esac
