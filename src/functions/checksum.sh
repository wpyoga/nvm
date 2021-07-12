nvm_get_checksum_binary() {
  if nvm_has_non_aliased 'sha256sum'; then
    nvm_echo 'sha256sum'
  elif nvm_has_non_aliased 'shasum'; then
    nvm_echo 'shasum'
  elif nvm_has_non_aliased 'sha256'; then
    nvm_echo 'sha256'
  elif nvm_has_non_aliased 'gsha256sum'; then
    nvm_echo 'gsha256sum'
  elif nvm_has_non_aliased 'openssl'; then
    nvm_echo 'openssl'
  elif nvm_has_non_aliased 'bssl'; then
    nvm_echo 'bssl'
  elif nvm_has_non_aliased 'sha1sum'; then
    nvm_echo 'sha1sum'
  elif nvm_has_non_aliased 'sha1'; then
    nvm_echo 'sha1'
  else
    nvm_err 'Unaliased sha256sum, shasum, sha256, gsha256sum, openssl, or bssl not found.'
    nvm_err 'Unaliased sha1sum or sha1 not found.'
    return 1
  fi
}

nvm_get_checksum_alg() {
  local NVM_CHECKSUM_BIN
  NVM_CHECKSUM_BIN="$(nvm_get_checksum_binary 2>/dev/null)"
  case "${NVM_CHECKSUM_BIN-}" in
    sha256sum | shasum | sha256 | gsha256sum | openssl | bssl)
      nvm_echo 'sha-256'
    ;;
    sha1sum | sha1)
      nvm_echo 'sha-1'
    ;;
    *)
      nvm_get_checksum_binary
      return $?
    ;;
  esac
}

nvm_compute_checksum() {
  local FILE
  FILE="${1-}"
  if [ -z "${FILE}" ]; then
    nvm_err 'Provided file to checksum is empty.'
    return 2
  elif ! [ -f "${FILE}" ]; then
    nvm_err 'Provided file to checksum does not exist.'
    return 1
  fi

  if nvm_has_non_aliased "sha256sum"; then
    nvm_err 'Computing checksum with sha256sum'
    command sha256sum "${FILE}" | command awk '{print $1}'
  elif nvm_has_non_aliased "shasum"; then
    nvm_err 'Computing checksum with shasum -a 256'
    command shasum -a 256 "${FILE}" | command awk '{print $1}'
  elif nvm_has_non_aliased "sha256"; then
    nvm_err 'Computing checksum with sha256 -q'
    command sha256 -q "${FILE}" | command awk '{print $1}'
  elif nvm_has_non_aliased "gsha256sum"; then
    nvm_err 'Computing checksum with gsha256sum'
    command gsha256sum "${FILE}" | command awk '{print $1}'
  elif nvm_has_non_aliased "openssl"; then
    nvm_err 'Computing checksum with openssl dgst -sha256'
    command openssl dgst -sha256 "${FILE}" | command awk '{print $NF}'
  elif nvm_has_non_aliased "bssl"; then
    nvm_err 'Computing checksum with bssl sha256sum'
    command bssl sha256sum "${FILE}" | command awk '{print $1}'
  elif nvm_has_non_aliased "sha1sum"; then
    nvm_err 'Computing checksum with sha1sum'
    command sha1sum "${FILE}" | command awk '{print $1}'
  elif nvm_has_non_aliased "sha1"; then
    nvm_err 'Computing checksum with sha1 -q'
    command sha1 -q "${FILE}"
  fi
}

nvm_compare_checksum() {
  local FILE
  FILE="${1-}"
  if [ -z "${FILE}" ]; then
    nvm_err 'Provided file to checksum is empty.'
    return 4
  elif ! [ -f "${FILE}" ]; then
    nvm_err 'Provided file to checksum does not exist.'
    return 3
  fi

  local COMPUTED_SUM
  COMPUTED_SUM="$(nvm_compute_checksum "${FILE}")"

  local CHECKSUM
  CHECKSUM="${2-}"
  if [ -z "${CHECKSUM}" ]; then
    nvm_err 'Provided checksum to compare to is empty.'
    return 2
  fi

  if [ -z "${COMPUTED_SUM}" ]; then
    nvm_err "Computed checksum of '${FILE}' is empty." # missing in raspberry pi binary
    nvm_err 'WARNING: Continuing *without checksum verification*'
    return
  elif [ "${COMPUTED_SUM}" != "${CHECKSUM}" ]; then
    nvm_err "Checksums do not match: '${COMPUTED_SUM}' found, '${CHECKSUM}' expected."
    return 1
  fi
  nvm_err 'Checksums matched!'
}

# args: flavor, type, version, slug, compression
nvm_get_checksum() {
  local FLAVOR
  case "${1-}" in
    node | iojs) FLAVOR="${1}" ;;
    *)
      nvm_err 'supported flavors: node, iojs'
      return 2
    ;;
  esac

  local MIRROR
  MIRROR="$(nvm_get_mirror "${FLAVOR}" "${2-}")"
  if [ -z "${MIRROR}" ]; then
    return 1
  fi

  local SHASUMS_URL
  if [ "$(nvm_get_checksum_alg)" = 'sha-256' ]; then
    SHASUMS_URL="${MIRROR}/${3}/SHASUMS256.txt"
  else
    SHASUMS_URL="${MIRROR}/${3}/SHASUMS.txt"
  fi

  nvm_download -L -s "${SHASUMS_URL}" -o - | command awk "{ if (\"${4}.${5}\" == \$2) print \$1}"
}
