local version_not_provided
version_not_provided=0
local NVM_OS
NVM_OS="$(nvm_get_os)"

if ! nvm_has "curl" && ! nvm_has "wget"; then
  nvm_err 'nvm needs curl or wget to proceed.'
  return 1
fi

if [ $# -lt 1 ]; then
  version_not_provided=1
fi

local nobinary
local nosource
local noprogress
nobinary=0
noprogress=0
nosource=0
local LTS
local ALIAS
local NVM_UPGRADE_NPM
NVM_UPGRADE_NPM=0

local PROVIDED_REINSTALL_PACKAGES_FROM
local REINSTALL_PACKAGES_FROM
local SKIP_DEFAULT_PACKAGES
local DEFAULT_PACKAGES

while [ $# -ne 0 ]; do
  case "$1" in
    ---*)
      nvm_err 'arguments with `---` are not supported - this is likely a typo'
      return 55;
    ;;
    -s)
      shift # consume "-s"
      nobinary=1
      if [ $nosource -eq 1 ]; then
          nvm err '-s and -b cannot be set together since they would skip install from both binary and source'
          return 6
      fi
    ;;
    -b)
      shift # consume "-b"
      nosource=1
      if [ $nobinary -eq 1 ]; then
          nvm err '-s and -b cannot be set together since they would skip install from both binary and source'
          return 6
      fi
    ;;
    -j)
      shift # consume "-j"
      nvm_get_make_jobs "$1"
      shift # consume job count
    ;;
    --no-progress)
      noprogress=1
      shift
    ;;
    --lts)
      LTS='*'
      shift
    ;;
    --lts=*)
      LTS="${1##--lts=}"
      shift
    ;;
    --latest-npm)
      NVM_UPGRADE_NPM=1
      shift
    ;;
    --default)
      if [ -n "${ALIAS-}" ]; then
        nvm_err '--default and --alias are mutually exclusive, and may not be provided more than once'
        return 6
      fi
      ALIAS='default'
      shift
    ;;
    --alias=*)
      if [ -n "${ALIAS-}" ]; then
        nvm_err '--default and --alias are mutually exclusive, and may not be provided more than once'
        return 6
      fi
      ALIAS="${1##--alias=}"
      shift
    ;;
    --reinstall-packages-from=*)
      if [ -n "${PROVIDED_REINSTALL_PACKAGES_FROM-}" ]; then
        nvm_err '--reinstall-packages-from may not be provided more than once'
        return 6
      fi
      PROVIDED_REINSTALL_PACKAGES_FROM="$(nvm_echo "$1" | command cut -c 27-)"
      if [ -z "${PROVIDED_REINSTALL_PACKAGES_FROM}" ]; then
        nvm_err 'If --reinstall-packages-from is provided, it must point to an installed version of node.'
        return 6
      fi
      REINSTALL_PACKAGES_FROM="$(nvm_version "${PROVIDED_REINSTALL_PACKAGES_FROM}")" ||:
      shift
    ;;
    --copy-packages-from=*)
      if [ -n "${PROVIDED_REINSTALL_PACKAGES_FROM-}" ]; then
        nvm_err '--reinstall-packages-from may not be provided more than once, or combined with `--copy-packages-from`'
        return 6
      fi
      PROVIDED_REINSTALL_PACKAGES_FROM="$(nvm_echo "$1" | command cut -c 22-)"
      if [ -z "${PROVIDED_REINSTALL_PACKAGES_FROM}" ]; then
        nvm_err 'If --copy-packages-from is provided, it must point to an installed version of node.'
        return 6
      fi
      REINSTALL_PACKAGES_FROM="$(nvm_version "${PROVIDED_REINSTALL_PACKAGES_FROM}")" ||:
      shift
    ;;
    --reinstall-packages-from | --copy-packages-from)
      nvm_err "If ${1} is provided, it must point to an installed version of node using \`=\`."
      return 6
    ;;
    --skip-default-packages)
      SKIP_DEFAULT_PACKAGES=true
      shift
    ;;
    *)
      break # stop parsing args
    ;;
  esac
done

local provided_version
provided_version="${1-}"

if [ -z "${provided_version}" ]; then
  if [ "_${LTS-}" = '_*' ]; then
    nvm_echo 'Installing latest LTS version.'
    if [ $# -gt 0 ]; then
      shift
    fi
  elif [ "_${LTS-}" != '_' ]; then
    nvm_echo "Installing with latest version of LTS line: ${LTS}"
    if [ $# -gt 0 ]; then
      shift
    fi
  else
    nvm_rc_version
    if [ $version_not_provided -eq 1 ] && [ -z "${NVM_RC_VERSION}" ]; then
      unset NVM_RC_VERSION
      >&2 nvm --help
      return 127
    fi
    provided_version="${NVM_RC_VERSION}"
    unset NVM_RC_VERSION
  fi
elif [ $# -gt 0 ]; then
  shift
fi

case "${provided_version}" in
  'lts/*')
    LTS='*'
    provided_version=''
  ;;
  lts/*)
    LTS="${provided_version##lts/}"
    provided_version=''
  ;;
esac

VERSION="$(NVM_VERSION_ONLY=true NVM_LTS="${LTS-}" nvm_remote_version "${provided_version}")"

if [ "${VERSION}" = 'N/A' ]; then
  local LTS_MSG
  local REMOTE_CMD
  if [ "${LTS-}" = '*' ]; then
    LTS_MSG='(with LTS filter) '
    REMOTE_CMD='nvm ls-remote --lts'
  elif [ -n "${LTS-}" ]; then
    LTS_MSG="(with LTS filter '${LTS}') "
    REMOTE_CMD="nvm ls-remote --lts=${LTS}"
  else
    REMOTE_CMD='nvm ls-remote'
  fi
  nvm_err "Version '${provided_version}' ${LTS_MSG-}not found - try \`${REMOTE_CMD}\` to browse available versions."
  return 3
fi

ADDITIONAL_PARAMETERS=''

while [ $# -ne 0 ]; do
  case "$1" in
    --reinstall-packages-from=*)
      if [ -n "${PROVIDED_REINSTALL_PACKAGES_FROM-}" ]; then
        nvm_err '--reinstall-packages-from may not be provided more than once'
        return 6
      fi
      PROVIDED_REINSTALL_PACKAGES_FROM="$(nvm_echo "$1" | command cut -c 27-)"
      if [ -z "${PROVIDED_REINSTALL_PACKAGES_FROM}" ]; then
        nvm_err 'If --reinstall-packages-from is provided, it must point to an installed version of node.'
        return 6
      fi
      REINSTALL_PACKAGES_FROM="$(nvm_version "${PROVIDED_REINSTALL_PACKAGES_FROM}")" ||:
    ;;
    --copy-packages-from=*)
      if [ -n "${PROVIDED_REINSTALL_PACKAGES_FROM-}" ]; then
        nvm_err '--reinstall-packages-from may not be provided more than once, or combined with `--copy-packages-from`'
        return 6
      fi
      PROVIDED_REINSTALL_PACKAGES_FROM="$(nvm_echo "$1" | command cut -c 22-)"
      if [ -z "${PROVIDED_REINSTALL_PACKAGES_FROM}" ]; then
        nvm_err 'If --copy-packages-from is provided, it must point to an installed version of node.'
        return 6
      fi
      REINSTALL_PACKAGES_FROM="$(nvm_version "${PROVIDED_REINSTALL_PACKAGES_FROM}")" ||:
    ;;
    --reinstall-packages-from | --copy-packages-from)
      nvm_err "If ${1} is provided, it must point to an installed version of node using \`=\`."
      return 6
    ;;
    --skip-default-packages)
      SKIP_DEFAULT_PACKAGES=true
    ;;
    *)
      ADDITIONAL_PARAMETERS="${ADDITIONAL_PARAMETERS} $1"
    ;;
  esac
  shift
done

if [ -z "${SKIP_DEFAULT_PACKAGES-}" ]; then
  DEFAULT_PACKAGES="$(nvm_get_default_packages)"
  EXIT_CODE=$?
  if [ $EXIT_CODE -ne 0 ]; then
    return $EXIT_CODE
  fi
fi

if [ -n "${PROVIDED_REINSTALL_PACKAGES_FROM-}" ] && [ "$(nvm_ensure_version_prefix "${PROVIDED_REINSTALL_PACKAGES_FROM}")" = "${VERSION}" ]; then
  nvm_err "You can't reinstall global packages from the same version of node you're installing."
  return 4
elif [ "${REINSTALL_PACKAGES_FROM-}" = 'N/A' ]; then
  nvm_err "If --reinstall-packages-from is provided, it must point to an installed version of node."
  return 5
fi

local FLAVOR
if nvm_is_iojs_version "${VERSION}"; then
  FLAVOR="$(nvm_iojs_prefix)"
else
  FLAVOR="$(nvm_node_prefix)"
fi

if nvm_is_version_installed "${VERSION}"; then
  nvm_err "${VERSION} is already installed."
  if nvm use "${VERSION}"; then
    if [ "${NVM_UPGRADE_NPM}" = 1 ]; then
      nvm install-latest-npm
    fi
    if [ -z "${SKIP_DEFAULT_PACKAGES-}" ] && [ -n "${DEFAULT_PACKAGES-}" ]; then
      nvm_install_default_packages "${DEFAULT_PACKAGES}"
    fi
    if [ -n "${REINSTALL_PACKAGES_FROM-}" ] && [ "_${REINSTALL_PACKAGES_FROM}" != "_N/A" ]; then
      nvm reinstall-packages "${REINSTALL_PACKAGES_FROM}"
    fi
  fi
  if [ -n "${LTS-}" ]; then
    LTS="$(echo "${LTS}" | tr '[:upper:]' '[:lower:]')"
    nvm_ensure_default_set "lts/${LTS}"
  else
    nvm_ensure_default_set "${provided_version}"
  fi

  if [ -n "${ALIAS-}" ]; then
    nvm alias "${ALIAS}" "${provided_version}"
  fi

  return $?
fi

local EXIT_CODE
EXIT_CODE=-1
if [ -n "${NVM_INSTALL_THIRD_PARTY_HOOK-}" ]; then
  nvm_err '** $NVM_INSTALL_THIRD_PARTY_HOOK env var set; dispatching to third-party installation method **'
  local NVM_METHOD_PREFERENCE
  NVM_METHOD_PREFERENCE='binary'
  if [ $nobinary -eq 1 ]; then
    NVM_METHOD_PREFERENCE='source'
  fi
  local VERSION_PATH
  VERSION_PATH="$(nvm_version_path "${VERSION}")"
  "${NVM_INSTALL_THIRD_PARTY_HOOK}" "${VERSION}" "${FLAVOR}" std "${NVM_METHOD_PREFERENCE}" "${VERSION_PATH}" || {
    EXIT_CODE=$?
    nvm_err '*** Third-party $NVM_INSTALL_THIRD_PARTY_HOOK env var failed to install! ***'
    return $EXIT_CODE
  }
  if ! nvm_is_version_installed "${VERSION}"; then
    nvm_err '*** Third-party $NVM_INSTALL_THIRD_PARTY_HOOK env var claimed to succeed, but failed to install! ***'
    return 33
  fi
  EXIT_CODE=0
else

  if [ "_${NVM_OS}" = "_freebsd" ]; then
    # node.js and io.js do not have a FreeBSD binary
    nobinary=1
    nvm_err "Currently, there is no binary for FreeBSD"
  elif [ "_${NVM_OS}" = "_sunos" ]; then
    # Not all node/io.js versions have a Solaris binary
    if ! nvm_has_solaris_binary "${VERSION}"; then
      nobinary=1
      nvm_err "Currently, there is no binary of version ${VERSION} for SunOS"
    fi
  fi

  # skip binary install if "nobinary" option specified.
  if [ $nobinary -ne 1 ] && nvm_binary_available "${VERSION}"; then
    NVM_NO_PROGRESS="${NVM_NO_PROGRESS:-${noprogress}}" nvm_install_binary "${FLAVOR}" std "${VERSION}" "${nosource}"
    EXIT_CODE=$?
  fi
  if [ $EXIT_CODE -ne 0 ]; then
    if [ -z "${NVM_MAKE_JOBS-}" ]; then
      nvm_get_make_jobs
    fi

    if [ "_${NVM_OS}" = "_win" ]; then
      nvm_err 'Installing from source on non-WSL Windows is not supported'
      EXIT_CODE=87
    else
      NVM_NO_PROGRESS="${NVM_NO_PROGRESS:-${noprogress}}" nvm_install_source "${FLAVOR}" std "${VERSION}" "${NVM_MAKE_JOBS}" "${ADDITIONAL_PARAMETERS}"
      EXIT_CODE=$?
    fi
  fi

fi

if [ $EXIT_CODE -eq 0 ] && nvm_use_if_needed "${VERSION}" && nvm_install_npm_if_needed "${VERSION}"; then
  if [ -n "${LTS-}" ]; then
    nvm_ensure_default_set "lts/${LTS}"
  else
    nvm_ensure_default_set "${provided_version}"
  fi
  if [ "${NVM_UPGRADE_NPM}" = 1 ]; then
    nvm install-latest-npm
    EXIT_CODE=$?
  fi
  if [ -z "${SKIP_DEFAULT_PACKAGES-}" ] && [ -n "${DEFAULT_PACKAGES-}" ]; then
    nvm_install_default_packages "${DEFAULT_PACKAGES}"
  fi
  if [ -n "${REINSTALL_PACKAGES_FROM-}" ] && [ "_${REINSTALL_PACKAGES_FROM}" != "_N/A" ]; then
    nvm reinstall-packages "${REINSTALL_PACKAGES_FROM}"
    EXIT_CODE=$?
  fi
else
  EXIT_CODE=$?
fi
return $EXIT_CODE
