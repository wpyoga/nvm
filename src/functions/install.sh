nvm_get_mirror() {
  case "${1}-${2}" in
    node-std) nvm_echo "${NVM_NODEJS_ORG_MIRROR:-https://nodejs.org/dist}" ;;
    iojs-std) nvm_echo "${NVM_IOJS_ORG_MIRROR:-https://iojs.org/dist}" ;;
    *)
      nvm_err 'unknown type of node.js or io.js release'
      return 1
    ;;
  esac
}

# args: os, prefixed version, version, tarball, extract directory
nvm_install_binary_extract() {
  if [ "$#" -ne 5 ]; then
    nvm_err 'nvm_install_binary_extract needs 5 parameters'
    return 1
  fi

  local NVM_OS
  local PREFIXED_VERSION
  local VERSION
  local TARBALL
  local TMPDIR
  NVM_OS="${1}"
  PREFIXED_VERSION="${2}"
  VERSION="${3}"
  TARBALL="${4}"
  TMPDIR="${5}"

  local VERSION_PATH

  [ -n "${TMPDIR-}" ] && \
  command mkdir -p "${TMPDIR}" && \
  VERSION_PATH="$(nvm_version_path "${PREFIXED_VERSION}")" || return 1

  # For Windows system (GitBash with MSYS, Cygwin)
  if [ "${NVM_OS}" = 'win' ]; then
    VERSION_PATH="${VERSION_PATH}/bin"
    command unzip -q "${TARBALL}" -d "${TMPDIR}" || return 1
  # For non Windows system (including WSL running on Windows)
  else
    local tar_compression_flag
    tar_compression_flag='z'
    if nvm_supports_xz "${VERSION}"; then
      tar_compression_flag='J'
    fi

    local tar
    if [ "${NVM_OS}" = 'aix' ]; then
      tar='gtar'
    else
      tar='tar'
    fi
    command "${tar}" -x${tar_compression_flag}f "${TARBALL}" -C "${TMPDIR}" --strip-components 1 || return 1
  fi

  command mkdir -p "${VERSION_PATH}" || return 1

  if [ "${NVM_OS}" = 'win' ]; then
    command mv "${TMPDIR}/"*/* "${VERSION_PATH}" || return 1
    command chmod +x "${VERSION_PATH}"/node.exe || return 1
    command chmod +x "${VERSION_PATH}"/npm || return 1
    command chmod +x "${VERSION_PATH}"/npx 2>/dev/null
  else
    command mv "${TMPDIR}/"* "${VERSION_PATH}" || return 1
  fi

  command rm -rf "${TMPDIR}"

  return 0
}

# args: flavor, type, version, reinstall
nvm_install_binary() {
  local FLAVOR
  case "${1-}" in
    node | iojs) FLAVOR="${1}" ;;
    *)
      nvm_err 'supported flavors: node, iojs'
      return 4
    ;;
  esac

  local TYPE
  TYPE="${2-}"

  local PREFIXED_VERSION
  PREFIXED_VERSION="${3-}"
  if [ -z "${PREFIXED_VERSION}" ]; then
    nvm_err 'A version number is required.'
    return 3
  fi

  local nosource
  nosource="${4-}"

  local VERSION
  VERSION="$(nvm_strip_iojs_prefix "${PREFIXED_VERSION}")"

  local NVM_OS
  NVM_OS="$(nvm_get_os)"

  if [ -z "${NVM_OS}" ]; then
    return 2
  fi

  local TARBALL
  local TMPDIR

  local PROGRESS_BAR
  local NODE_OR_IOJS
  if [ "${FLAVOR}" = 'node' ]; then
    NODE_OR_IOJS="${FLAVOR}"
  elif [ "${FLAVOR}" = 'iojs' ]; then
    NODE_OR_IOJS="io.js"
  fi
  if [ "${NVM_NO_PROGRESS-}" = "1" ]; then
    # --silent, --show-error, use short option as @samrocketman mentions the compatibility issue.
    PROGRESS_BAR="-sS"
  else
    PROGRESS_BAR="--progress-bar"
  fi
  nvm_echo "Downloading and installing ${NODE_OR_IOJS-} ${VERSION}..."
  TARBALL="$(PROGRESS_BAR="${PROGRESS_BAR}" nvm_download_artifact "${FLAVOR}" binary "${TYPE-}" "${VERSION}" | command tail -1)"
  if [ -f "${TARBALL}" ]; then
    TMPDIR="$(dirname "${TARBALL}")/files"
  fi

  if nvm_install_binary_extract "${NVM_OS}" "${PREFIXED_VERSION}" "${VERSION}" "${TARBALL}" "${TMPDIR}"; then
    if [ -n "${ALIAS-}" ]; then
      nvm alias "${ALIAS}" "${provided_version}"
    fi
    return 0
  fi


  # Read nosource from arguments
  if [ "${nosource-}" = '1' ]; then
      nvm_err 'Binary download failed. Download from source aborted.'
      return 0
  fi

  nvm_err 'Binary download failed, trying source.'
  if [ -n "${TMPDIR-}" ]; then
    command rm -rf "${TMPDIR}"
  fi
  return 1
}

# args: flavor, kind, version
nvm_get_download_slug() {
  local FLAVOR
  case "${1-}" in
    node | iojs) FLAVOR="${1}" ;;
    *)
      nvm_err 'supported flavors: node, iojs'
      return 1
    ;;
  esac

  local KIND
  case "${2-}" in
    binary | source) KIND="${2}" ;;
    *)
      nvm_err 'supported kinds: binary, source'
      return 2
    ;;
  esac

  local VERSION
  VERSION="${3-}"

  local NVM_OS
  NVM_OS="$(nvm_get_os)"

  local NVM_ARCH
  NVM_ARCH="$(nvm_get_arch)"
  if ! nvm_is_merged_node_version "${VERSION}"; then
    if [ "${NVM_ARCH}" = 'armv6l' ] || [ "${NVM_ARCH}" = 'armv7l' ]; then
      NVM_ARCH="arm-pi"
    fi
  fi

  if [ "${KIND}" = 'binary' ]; then
    nvm_echo "${FLAVOR}-${VERSION}-${NVM_OS}-${NVM_ARCH}"
  elif [ "${KIND}" = 'source' ]; then
    nvm_echo "${FLAVOR}-${VERSION}"
  fi
}

nvm_get_artifact_compression() {
  local VERSION
  VERSION="${1-}"

  local NVM_OS
  NVM_OS="$(nvm_get_os)"

  local COMPRESSION
  COMPRESSION='tar.gz'
  if [ "_${NVM_OS}" = '_win' ]; then
    COMPRESSION='zip'
  elif nvm_supports_xz "${VERSION}"; then
    COMPRESSION='tar.xz'
  fi

  nvm_echo "${COMPRESSION}"
}

# args: flavor, kind, type, version
nvm_download_artifact() {
  local FLAVOR
  case "${1-}" in
    node | iojs) FLAVOR="${1}" ;;
    *)
      nvm_err 'supported flavors: node, iojs'
      return 1
    ;;
  esac

  local KIND
  case "${2-}" in
    binary | source) KIND="${2}" ;;
    *)
      nvm_err 'supported kinds: binary, source'
      return 1
    ;;
  esac

  local TYPE
  TYPE="${3-}"

  local MIRROR
  MIRROR="$(nvm_get_mirror "${FLAVOR}" "${TYPE}")"
  if [ -z "${MIRROR}" ]; then
    return 2
  fi

  local VERSION
  VERSION="${4}"

  if [ -z "${VERSION}" ]; then
    nvm_err 'A version number is required.'
    return 3
  fi

  if [ "${KIND}" = 'binary' ] && ! nvm_binary_available "${VERSION}"; then
    nvm_err "No precompiled binary available for ${VERSION}."
    return
  fi

  local SLUG
  SLUG="$(nvm_get_download_slug "${FLAVOR}" "${KIND}" "${VERSION}")"

  local COMPRESSION
  COMPRESSION="$(nvm_get_artifact_compression "${VERSION}")"

  local CHECKSUM
  CHECKSUM="$(nvm_get_checksum "${FLAVOR}" "${TYPE}" "${VERSION}" "${SLUG}" "${COMPRESSION}")"

  local tmpdir
  if [ "${KIND}" = 'binary' ]; then
    tmpdir="$(nvm_cache_dir)/bin/${SLUG}"
  else
    tmpdir="$(nvm_cache_dir)/src/${SLUG}"
  fi
  command mkdir -p "${tmpdir}/files" || (
    nvm_err "creating directory ${tmpdir}/files failed"
    return 3
  )

  local TARBALL
  TARBALL="${tmpdir}/${SLUG}.${COMPRESSION}"
  local TARBALL_URL
  if nvm_version_greater_than_or_equal_to "${VERSION}" 0.1.14; then
    TARBALL_URL="${MIRROR}/${VERSION}/${SLUG}.${COMPRESSION}"
  else
    # node <= 0.1.13 does not have a directory
    TARBALL_URL="${MIRROR}/${SLUG}.${COMPRESSION}"
  fi

  if [ -r "${TARBALL}" ]; then
    nvm_err "Local cache found: $(nvm_sanitize_path "${TARBALL}")"
    if nvm_compare_checksum "${TARBALL}" "${CHECKSUM}" >/dev/null 2>&1; then
      nvm_err "Checksums match! Using existing downloaded archive $(nvm_sanitize_path "${TARBALL}")"
      nvm_echo "${TARBALL}"
      return 0
    fi
    nvm_compare_checksum "${TARBALL}" "${CHECKSUM}"
    nvm_err "Checksum check failed!"
    nvm_err "Removing the broken local cache..."
    command rm -rf "${TARBALL}"
  fi
  nvm_err "Downloading ${TARBALL_URL}..."
  nvm_download -L -C - "${PROGRESS_BAR}" "${TARBALL_URL}" -o "${TARBALL}" || (
    command rm -rf "${TARBALL}" "${tmpdir}"
    nvm_err "Binary download from ${TARBALL_URL} failed, trying source."
    return 4
  )

  if nvm_grep '404 Not Found' "${TARBALL}" >/dev/null; then
    command rm -rf "${TARBALL}" "${tmpdir}"
    nvm_err "HTTP 404 at URL ${TARBALL_URL}"
    return 5
  fi

  nvm_compare_checksum "${TARBALL}" "${CHECKSUM}" || (
    command rm -rf "${tmpdir}/files"
    return 6
  )

  nvm_echo "${TARBALL}"
}

nvm_get_make_jobs() {
  if nvm_is_natural_num "${1-}"; then
    NVM_MAKE_JOBS="$1"
    nvm_echo "number of \`make\` jobs: ${NVM_MAKE_JOBS}"
    return
  elif [ -n "${1-}" ]; then
    unset NVM_MAKE_JOBS
    nvm_err "$1 is invalid for number of \`make\` jobs, must be a natural number"
  fi
  local NVM_OS
  NVM_OS="$(nvm_get_os)"
  local NVM_CPU_CORES
  case "_${NVM_OS}" in
    "_linux")
      NVM_CPU_CORES="$(nvm_grep -c -E '^processor.+: [0-9]+' /proc/cpuinfo)"
    ;;
    "_freebsd" | "_darwin" | "_openbsd")
      NVM_CPU_CORES="$(sysctl -n hw.ncpu)"
    ;;
    "_sunos")
      NVM_CPU_CORES="$(psrinfo | wc -l)"
    ;;
    "_aix")
      NVM_CPU_CORES="$(pmcycles -m | wc -l)"
    ;;
  esac
  if ! nvm_is_natural_num "${NVM_CPU_CORES}"; then
    nvm_err 'Can not determine how many core(s) are available, running in single-threaded mode.'
    nvm_err 'Please report an issue on GitHub to help us make nvm run faster on your computer!'
    NVM_MAKE_JOBS=1
  else
    nvm_echo "Detected that you have ${NVM_CPU_CORES} CPU core(s)"
    if [ "${NVM_CPU_CORES}" -gt 2 ]; then
      NVM_MAKE_JOBS=$((NVM_CPU_CORES - 1))
      nvm_echo "Running with ${NVM_MAKE_JOBS} threads to speed up the build"
    else
      NVM_MAKE_JOBS=1
      nvm_echo 'Number of CPU core(s) less than or equal to 2, running in single-threaded mode'
    fi
  fi
}

# args: flavor, type, version, make jobs, additional
nvm_install_source() {
  local FLAVOR
  case "${1-}" in
    node | iojs) FLAVOR="${1}" ;;
    *)
      nvm_err 'supported flavors: node, iojs'
      return 4
    ;;
  esac

  local TYPE
  TYPE="${2-}"

  local PREFIXED_VERSION
  PREFIXED_VERSION="${3-}"
  if [ -z "${PREFIXED_VERSION}" ]; then
    nvm_err 'A version number is required.'
    return 3
  fi

  local VERSION
  VERSION="$(nvm_strip_iojs_prefix "${PREFIXED_VERSION}")"

  local NVM_MAKE_JOBS
  NVM_MAKE_JOBS="${4-}"

  local ADDITIONAL_PARAMETERS
  ADDITIONAL_PARAMETERS="${5-}"

  local NVM_ARCH
  NVM_ARCH="$(nvm_get_arch)"
  if [ "${NVM_ARCH}" = 'armv6l' ] || [ "${NVM_ARCH}" = 'armv7l' ]; then
    if [ -n "${ADDITIONAL_PARAMETERS}" ]; then
      ADDITIONAL_PARAMETERS="--without-snapshot ${ADDITIONAL_PARAMETERS}"
    else
      ADDITIONAL_PARAMETERS='--without-snapshot'
    fi
  fi

  if [ -n "${ADDITIONAL_PARAMETERS}" ]; then
    nvm_echo "Additional options while compiling: ${ADDITIONAL_PARAMETERS}"
  fi

  local NVM_OS
  NVM_OS="$(nvm_get_os)"

  local make
  make='make'
  local MAKE_CXX
  case "${NVM_OS}" in
    'freebsd')
      make='gmake'
      MAKE_CXX="CC=${CC:-cc} CXX=${CXX:-c++}"
    ;;
    'darwin')
      MAKE_CXX="CC=${CC:-cc} CXX=${CXX:-c++}"
    ;;
    'aix')
      make='gmake'
    ;;
  esac
  if nvm_has "clang++" && nvm_has "clang" && nvm_version_greater_than_or_equal_to "$(nvm_clang_version)" 3.5; then
    if [ -z "${CC-}" ] || [ -z "${CXX-}" ]; then
      nvm_echo "Clang v3.5+ detected! CC or CXX not specified, will use Clang as C/C++ compiler!"
      MAKE_CXX="CC=${CC:-cc} CXX=${CXX:-c++}"
    fi
  fi

  local tar_compression_flag
  tar_compression_flag='z'
  if nvm_supports_xz "${VERSION}"; then
    tar_compression_flag='J'
  fi

  local tar
  tar='tar'
  if [ "${NVM_OS}" = 'aix' ]; then
    tar='gtar'
  fi

  local TARBALL
  local TMPDIR
  local VERSION_PATH

  if [ "${NVM_NO_PROGRESS-}" = "1" ]; then
    # --silent, --show-error, use short option as @samrocketman mentions the compatibility issue.
    PROGRESS_BAR="-sS"
  else
    PROGRESS_BAR="--progress-bar"
  fi

  nvm_is_zsh && setopt local_options shwordsplit

  TARBALL="$(PROGRESS_BAR="${PROGRESS_BAR}" nvm_download_artifact "${FLAVOR}" source "${TYPE}" "${VERSION}" | command tail -1)" && \
  [ -f "${TARBALL}" ] && \
  TMPDIR="$(dirname "${TARBALL}")/files" && \
  if ! (
    # shellcheck disable=SC2086
    command mkdir -p "${TMPDIR}" && \
    command "${tar}" -x${tar_compression_flag}f "${TARBALL}" -C "${TMPDIR}" --strip-components 1 && \
    VERSION_PATH="$(nvm_version_path "${PREFIXED_VERSION}")" && \
    nvm_cd "${TMPDIR}" && \
    nvm_echo '$>'./configure --prefix="${VERSION_PATH}" $ADDITIONAL_PARAMETERS'<' && \
    ./configure --prefix="${VERSION_PATH}" $ADDITIONAL_PARAMETERS && \
    $make -j "${NVM_MAKE_JOBS}" ${MAKE_CXX-} && \
    command rm -f "${VERSION_PATH}" 2>/dev/null && \
    $make -j "${NVM_MAKE_JOBS}" ${MAKE_CXX-} install
  ); then
    nvm_err "nvm: install ${VERSION} failed!"
    command rm -rf "${TMPDIR-}"
    return 1
  fi
}
