nvm_use_if_needed() {
  if [ "_${1-}" = "_$(nvm_ls_current)" ]; then
    return
  fi
  nvm use "$@"
}

nvm_install_npm_if_needed() {
  local VERSION
  VERSION="$(nvm_ls_current)"
  if ! nvm_has "npm"; then
    nvm_echo 'Installing npm...'
    if nvm_version_greater 0.2.0 "${VERSION}"; then
      nvm_err 'npm requires node v0.2.3 or higher'
    elif nvm_version_greater_than_or_equal_to "${VERSION}" 0.2.0; then
      if nvm_version_greater 0.2.3 "${VERSION}"; then
        nvm_err 'npm requires node v0.2.3 or higher'
      else
        nvm_download -L https://npmjs.org/install.sh -o - | clean=yes npm_install=0.2.19 sh
      fi
    else
      nvm_download -L https://npmjs.org/install.sh -o - | clean=yes sh
    fi
  fi
  return $?
}

nvm_match_version() {
  local NVM_IOJS_PREFIX
  NVM_IOJS_PREFIX="$(nvm_iojs_prefix)"
  local PROVIDED_VERSION
  PROVIDED_VERSION="$1"
  case "_${PROVIDED_VERSION}" in
    "_${NVM_IOJS_PREFIX}" | '_io.js')
      nvm_version "${NVM_IOJS_PREFIX}"
    ;;
    '_system')
      nvm_echo 'system'
    ;;
    *)
      nvm_version "${PROVIDED_VERSION}"
    ;;
  esac
}

nvm_npm_global_modules() {
  local NPMLIST
  local VERSION
  VERSION="$1"
  NPMLIST=$(nvm use "${VERSION}" >/dev/null && npm list -g --depth=0 2>/dev/null | command sed 1,1d | nvm_grep -v 'UNMET PEER DEPENDENCY')

  local INSTALLS
  INSTALLS=$(nvm_echo "${NPMLIST}" | command sed -e '/ -> / d' -e '/\(empty\)/ d' -e 's/^.* \(.*@[^ ]*\).*/\1/' -e '/^npm@[^ ]*.*$/ d' | command xargs)

  local LINKS
  LINKS="$(nvm_echo "${NPMLIST}" | command sed -n 's/.* -> \(.*\)/\1/ p')"

  nvm_echo "${INSTALLS} //// ${LINKS}"
}

nvm_npmrc_bad_news_bears() {
  local NVM_NPMRC
  NVM_NPMRC="${1-}"
  if [ -n "${NVM_NPMRC}" ] && [ -f "${NVM_NPMRC}" ] && nvm_grep -Ee '^(prefix|globalconfig) *=' <"${NVM_NPMRC}" >/dev/null; then
    return 0
  fi
  return 1
}

nvm_die_on_prefix() {
  local NVM_DELETE_PREFIX
  NVM_DELETE_PREFIX="${1-}"
  case "${NVM_DELETE_PREFIX}" in
    0 | 1) ;;
    *)
      nvm_err 'First argument "delete the prefix" must be zero or one'
      return 1
    ;;
  esac
  local NVM_COMMAND
  NVM_COMMAND="${2-}"
  local NVM_VERSION_DIR
  NVM_VERSION_DIR="${3-}"
  if [ -z "${NVM_COMMAND}" ] || [ -z "${NVM_VERSION_DIR}" ]; then
    nvm_err 'Second argument "nvm command", and third argument "nvm version dir", must both be nonempty'
    return 2
  fi

  # npm first looks at $PREFIX (case-sensitive)
  # we do not bother to test the value here; if this env var is set, unset it to continue.
  # however, `npm exec` in npm v7.2+ sets $PREFIX; if set, inherit it
  if [ -n "${PREFIX-}" ] && [ "$(nvm_version_path "$(node -v)")" != "${PREFIX}" ]; then
    nvm deactivate >/dev/null 2>&1
    nvm_err "nvm is not compatible with the \"PREFIX\" environment variable: currently set to \"${PREFIX}\""
    nvm_err 'Run `unset PREFIX` to unset it.'
    return 3
  fi

  local NVM_OS
  NVM_OS="$(nvm_get_os)"

  # npm normalizes NPM_CONFIG_-prefixed env vars
  # https://github.com/npm/npmconf/blob/22827e4038d6eebaafeb5c13ed2b92cf97b8fb82/npmconf.js#L331-L348
  # https://github.com/npm/npm/blob/5e426a78ca02d0044f8dd26e0c5f881217081cbd/lib/config/core.js#L343-L359
  #
  # here, we avoid trying to replicate "which one wins" or testing the value; if any are defined, it errors
  # until none are left.
  local NVM_NPM_CONFIG_PREFIX_ENV
  NVM_NPM_CONFIG_PREFIX_ENV="$(command env | nvm_grep -i NPM_CONFIG_PREFIX | command tail -1 | command awk -F '=' '{print $1}')"
  if [ -n "${NVM_NPM_CONFIG_PREFIX_ENV-}" ]; then
    local NVM_CONFIG_VALUE
    eval "NVM_CONFIG_VALUE=\"\$${NVM_NPM_CONFIG_PREFIX_ENV}\""
    if [ -n "${NVM_CONFIG_VALUE-}" ] && [ "_${NVM_OS}" = "_win" ]; then
      NVM_CONFIG_VALUE="$(cd "$NVM_CONFIG_VALUE" 2>/dev/null && pwd)"
    fi
    if [ -n "${NVM_CONFIG_VALUE-}" ] && ! nvm_tree_contains_path "${NVM_DIR}" "${NVM_CONFIG_VALUE}"; then
      nvm deactivate >/dev/null 2>&1
      nvm_err "nvm is not compatible with the \"${NVM_NPM_CONFIG_PREFIX_ENV}\" environment variable: currently set to \"${NVM_CONFIG_VALUE}\""
      nvm_err "Run \`unset ${NVM_NPM_CONFIG_PREFIX_ENV}\` to unset it."
      return 4
    fi
  fi

  # here, npm config checks npmrc files.
  # the stack is: cli, env, project, user, global, builtin, defaults
  # cli does not apply; env is covered above, defaults don't exist for prefix
  # there are 4 npmrc locations to check: project, global, user, and builtin
  # project: find the closest node_modules or package.json-containing dir, `.npmrc`
  # global: default prefix + `/etc/npmrc`
  # user: $HOME/.npmrc
  # builtin: npm install location, `npmrc`
  #
  # if any of them have a `prefix`, fail.
  # if any have `globalconfig`, fail also, just in case, to avoid spidering configs.

  local NVM_NPM_BUILTIN_NPMRC
  NVM_NPM_BUILTIN_NPMRC="${NVM_VERSION_DIR}/lib/node_modules/npm/npmrc"
  if nvm_npmrc_bad_news_bears "${NVM_NPM_BUILTIN_NPMRC}"; then
    if [ "_${NVM_DELETE_PREFIX}" = "_1" ]; then
      npm config --loglevel=warn delete prefix --userconfig="${NVM_NPM_BUILTIN_NPMRC}"
      npm config --loglevel=warn delete globalconfig --userconfig="${NVM_NPM_BUILTIN_NPMRC}"
    else
      nvm_err "Your builtin npmrc file ($(nvm_sanitize_path "${NVM_NPM_BUILTIN_NPMRC}"))"
      nvm_err 'has a `globalconfig` and/or a `prefix` setting, which are incompatible with nvm.'
      nvm_err "Run \`${NVM_COMMAND}\` to unset it."
      return 10
    fi
  fi

  local NVM_NPM_GLOBAL_NPMRC
  NVM_NPM_GLOBAL_NPMRC="${NVM_VERSION_DIR}/etc/npmrc"
  if nvm_npmrc_bad_news_bears "${NVM_NPM_GLOBAL_NPMRC}"; then
    if [ "_${NVM_DELETE_PREFIX}" = "_1" ]; then
      npm config --global --loglevel=warn delete prefix
      npm config --global --loglevel=warn delete globalconfig
    else
      nvm_err "Your global npmrc file ($(nvm_sanitize_path "${NVM_NPM_GLOBAL_NPMRC}"))"
      nvm_err 'has a `globalconfig` and/or a `prefix` setting, which are incompatible with nvm.'
      nvm_err "Run \`${NVM_COMMAND}\` to unset it."
      return 10
    fi
  fi

  local NVM_NPM_USER_NPMRC
  NVM_NPM_USER_NPMRC="${HOME}/.npmrc"
  if nvm_npmrc_bad_news_bears "${NVM_NPM_USER_NPMRC}"; then
    if [ "_${NVM_DELETE_PREFIX}" = "_1" ]; then
      npm config --loglevel=warn delete prefix --userconfig="${NVM_NPM_USER_NPMRC}"
      npm config --loglevel=warn delete globalconfig --userconfig="${NVM_NPM_USER_NPMRC}"
    else
      nvm_err "Your user’s .npmrc file ($(nvm_sanitize_path "${NVM_NPM_USER_NPMRC}"))"
      nvm_err 'has a `globalconfig` and/or a `prefix` setting, which are incompatible with nvm.'
      nvm_err "Run \`${NVM_COMMAND}\` to unset it."
      return 10
    fi
  fi

  local NVM_NPM_PROJECT_NPMRC
  NVM_NPM_PROJECT_NPMRC="$(nvm_find_project_dir)/.npmrc"
  if nvm_npmrc_bad_news_bears "${NVM_NPM_PROJECT_NPMRC}"; then
    if [ "_${NVM_DELETE_PREFIX}" = "_1" ]; then
      npm config --loglevel=warn delete prefix
      npm config --loglevel=warn delete globalconfig
    else
      nvm_err "Your project npmrc file ($(nvm_sanitize_path "${NVM_NPM_PROJECT_NPMRC}"))"
      nvm_err 'has a `globalconfig` and/or a `prefix` setting, which are incompatible with nvm.'
      nvm_err "Run \`${NVM_COMMAND}\` to unset it."
      return 10
    fi
  fi
}
