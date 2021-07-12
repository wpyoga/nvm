nvm_strip_path() {
  if [ -z "${NVM_DIR-}" ]; then
    nvm_err '${NVM_DIR} not set!'
    return 1
  fi
  nvm_echo "${1-}" | command sed \
    -e "s#${NVM_DIR}/[^/]*${2-}[^:]*:##g" \
    -e "s#:${NVM_DIR}/[^/]*${2-}[^:]*##g" \
    -e "s#${NVM_DIR}/[^/]*${2-}[^:]*##g" \
    -e "s#${NVM_DIR}/versions/[^/]*/[^/]*${2-}[^:]*:##g" \
    -e "s#:${NVM_DIR}/versions/[^/]*/[^/]*${2-}[^:]*##g" \
    -e "s#${NVM_DIR}/versions/[^/]*/[^/]*${2-}[^:]*##g"
}

nvm_change_path() {
  # if there’s no initial path, just return the supplementary path
  if [ -z "${1-}" ]; then
    nvm_echo "${3-}${2-}"
  # if the initial path doesn’t contain an nvm path, prepend the supplementary
  # path
  elif ! nvm_echo "${1-}" | nvm_grep -q "${NVM_DIR}/[^/]*${2-}" \
    && ! nvm_echo "${1-}" | nvm_grep -q "${NVM_DIR}/versions/[^/]*/[^/]*${2-}"; then
    nvm_echo "${3-}${2-}:${1-}"
  # if the initial path contains BOTH an nvm path (checked for above) and
  # that nvm path is preceded by a system binary path, just prepend the
  # supplementary path instead of replacing it.
  # https://github.com/nvm-sh/nvm/issues/1652#issuecomment-342571223
  elif nvm_echo "${1-}" | nvm_grep -Eq "(^|:)(/usr(/local)?)?${2-}:.*${NVM_DIR}/[^/]*${2-}" \
    || nvm_echo "${1-}" | nvm_grep -Eq "(^|:)(/usr(/local)?)?${2-}:.*${NVM_DIR}/versions/[^/]*/[^/]*${2-}"; then
    nvm_echo "${3-}${2-}:${1-}"
  # use sed to replace the existing nvm path with the supplementary path. This
  # preserves the order of the path.
  else
    nvm_echo "${1-}" | command sed \
      -e "s#${NVM_DIR}/[^/]*${2-}[^:]*#${3-}${2-}#" \
      -e "s#${NVM_DIR}/versions/[^/]*/[^/]*${2-}[^:]*#${3-}${2-}#"
  fi
}

nvm_binary_available() {
  # binaries started with node 0.8.6
  nvm_version_greater_than_or_equal_to "$(nvm_strip_iojs_prefix "${1-}")" v0.8.6
}
