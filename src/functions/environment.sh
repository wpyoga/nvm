nvm_get_os() {
  local NVM_UNAME
  NVM_UNAME="$(command uname -a)"
  local NVM_OS
  case "${NVM_UNAME}" in
    Linux\ *) NVM_OS=linux ;;
    Darwin\ *) NVM_OS=darwin ;;
    SunOS\ *) NVM_OS=sunos ;;
    FreeBSD\ *) NVM_OS=freebsd ;;
    OpenBSD\ *) NVM_OS=openbsd ;;
    AIX\ *) NVM_OS=aix ;;
    CYGWIN* | MSYS* | MINGW*) NVM_OS=win ;;
  esac
  nvm_echo "${NVM_OS-}"
}

nvm_get_arch() {
  local HOST_ARCH
  local NVM_OS
  local EXIT_CODE

  NVM_OS="$(nvm_get_os)"
  # If the OS is SunOS, first try to use pkgsrc to guess
  # the most appropriate arch. If it's not available, use
  # isainfo to get the instruction set supported by the
  # kernel.
  if [ "_${NVM_OS}" = "_sunos" ]; then
    if HOST_ARCH=$(pkg_info -Q MACHINE_ARCH pkg_install); then
      HOST_ARCH=$(nvm_echo "${HOST_ARCH}" | command tail -1)
    else
      HOST_ARCH=$(isainfo -n)
    fi
  elif [ "_${NVM_OS}" = "_aix" ]; then
    HOST_ARCH=ppc64
  else
    HOST_ARCH="$(command uname -m)"
  fi

  local NVM_ARCH
  case "${HOST_ARCH}" in
    x86_64 | amd64) NVM_ARCH="x64" ;;
    i*86) NVM_ARCH="x86" ;;
    aarch64) NVM_ARCH="arm64" ;;
    *) NVM_ARCH="${HOST_ARCH}" ;;
  esac

  # If running a 64bit ARM kernel but a 32bit ARM userland, change ARCH to 32bit ARM (armv7l)
  L=$(ls -dl /sbin/init) #                                         if /sbin/init is 32bit executable
  if [ "$(uname)" = "Linux" ] && [ "${NVM_ARCH}" = arm64 ] && [ "$(od -An -t x1 -j 4 -N 1 "${L#*-> }")" = ' 01' ]; then
    NVM_ARCH=armv7l
    HOST_ARCH=armv7l
  fi

  nvm_echo "${NVM_ARCH}"
}

nvm_get_minor_version() {
  local VERSION
  VERSION="$1"

  if [ -z "${VERSION}" ]; then
    nvm_err 'a version is required'
    return 1
  fi

  case "${VERSION}" in
    v | .* | *..* | v*[!.0123456789]* | [!v]*[!.0123456789]* | [!v0123456789]* | v[!0123456789]*)
      nvm_err 'invalid version number'
      return 2
    ;;
  esac

  local PREFIXED_VERSION
  PREFIXED_VERSION="$(nvm_format_version "${VERSION}")"

  local MINOR
  MINOR="$(nvm_echo "${PREFIXED_VERSION}" | nvm_grep -e '^v' | command cut -c2- | command cut -d . -f 1,2)"
  if [ -z "${MINOR}" ]; then
    nvm_err 'invalid version number! (please report this)'
    return 3
  fi
  nvm_echo "${MINOR}"
}
