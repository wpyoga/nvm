nvm_get_latest() {
  local NVM_LATEST_URL
  local CURL_COMPRESSED_FLAG
  if nvm_has "curl"; then
    if nvm_curl_use_compression; then
      CURL_COMPRESSED_FLAG="--compressed"
    fi
    NVM_LATEST_URL="$(curl ${CURL_COMPRESSED_FLAG:-} -q -w "%{url_effective}\\n" -L -s -S http://latest.nvm.sh -o /dev/null)"
  elif nvm_has "wget"; then
    NVM_LATEST_URL="$(wget -q http://latest.nvm.sh --server-response -O /dev/null 2>&1 | command awk '/^  Location: /{DEST=$2} END{ print DEST }')"
  else
    nvm_err 'nvm needs curl or wget to proceed.'
    return 1
  fi
  if [ -z "${NVM_LATEST_URL}" ]; then
    nvm_err "http://latest.nvm.sh did not redirect to the latest release on GitHub"
    return 2
  fi
  nvm_echo "${NVM_LATEST_URL##*/}"
}

nvm_download() {
  local CURL_COMPRESSED_FLAG
  if nvm_has "curl"; then
    if nvm_curl_use_compression; then
      CURL_COMPRESSED_FLAG="--compressed"
    fi
    curl --fail ${CURL_COMPRESSED_FLAG:-} -q "$@"
  elif nvm_has "wget"; then
    # Emulate curl with wget
    ARGS=$(nvm_echo "$@" | command sed -e 's/--progress-bar /--progress=bar /' \
                            -e 's/--compressed //' \
                            -e 's/--fail //' \
                            -e 's/-L //' \
                            -e 's/-I /--server-response /' \
                            -e 's/-s /-q /' \
                            -e 's/-sS /-nv /' \
                            -e 's/-o /-O /' \
                            -e 's/-C - /-c /')
    # shellcheck disable=SC2086
    eval wget $ARGS
  fi
}

nvm_has_system_node() {
  [ "$(nvm deactivate >/dev/null 2>&1 && command -v node)" != '' ]
}

nvm_has_system_iojs() {
  [ "$(nvm deactivate >/dev/null 2>&1 && command -v iojs)" != '' ]
}

nvm_is_version_installed() {
  if [ -z "${1-}" ]; then
    return 1
  fi
  local NVM_NODE_BINARY
  NVM_NODE_BINARY='node'
  if [ "_$(nvm_get_os)" = '_win' ]; then
    NVM_NODE_BINARY='node.exe'
  fi
  if [ -x "$(nvm_version_path "$1" 2>/dev/null)/bin/${NVM_NODE_BINARY}" ]; then
    return 0
  fi
  return 1
}

nvm_print_npm_version() {
  if nvm_has "npm"; then
    command printf " (npm v$(npm --version 2>/dev/null))"
  fi
}

nvm_install_latest_npm() {
  nvm_echo 'Attempting to upgrade to the latest working version of npm...'
  local NODE_VERSION
  NODE_VERSION="$(nvm_strip_iojs_prefix "$(nvm_ls_current)")"
  if [ "${NODE_VERSION}" = 'system' ]; then
    NODE_VERSION="$(node --version)"
  elif [ "${NODE_VERSION}" = 'none' ]; then
    nvm_echo "Detected node version ${NODE_VERSION}, npm version v${NPM_VERSION}"
    NODE_VERSION=''
  fi
  if [ -z "${NODE_VERSION}" ]; then
    nvm_err 'Unable to obtain node version.'
    return 1
  fi
  local NPM_VERSION
  NPM_VERSION="$(npm --version 2>/dev/null)"
  if [ -z "${NPM_VERSION}" ]; then
    nvm_err 'Unable to obtain npm version.'
    return 2
  fi

  local NVM_NPM_CMD
  NVM_NPM_CMD='npm'
  if [ "${NVM_DEBUG-}" = 1 ]; then
    nvm_echo "Detected node version ${NODE_VERSION}, npm version v${NPM_VERSION}"
    NVM_NPM_CMD='nvm_echo npm'
  fi

  local NVM_IS_0_6
  NVM_IS_0_6=0
  if nvm_version_greater_than_or_equal_to "${NODE_VERSION}" 0.6.0 && nvm_version_greater 0.7.0 "${NODE_VERSION}"; then
    NVM_IS_0_6=1
  fi
  local NVM_IS_0_9
  NVM_IS_0_9=0
  if nvm_version_greater_than_or_equal_to "${NODE_VERSION}" 0.9.0 && nvm_version_greater 0.10.0 "${NODE_VERSION}"; then
    NVM_IS_0_9=1
  fi

  if [ $NVM_IS_0_6 -eq 1 ]; then
    nvm_echo '* `node` v0.6.x can only upgrade to `npm` v1.3.x'
    $NVM_NPM_CMD install -g npm@1.3
  elif [ $NVM_IS_0_9 -eq 0 ]; then
    # node 0.9 breaks here, for some reason
    if nvm_version_greater_than_or_equal_to "${NPM_VERSION}" 1.0.0 && nvm_version_greater 2.0.0 "${NPM_VERSION}"; then
      nvm_echo '* `npm` v1.x needs to first jump to `npm` v1.4.28 to be able to upgrade further'
      $NVM_NPM_CMD install -g npm@1.4.28
    elif nvm_version_greater_than_or_equal_to "${NPM_VERSION}" 2.0.0 && nvm_version_greater 3.0.0 "${NPM_VERSION}"; then
      nvm_echo '* `npm` v2.x needs to first jump to the latest v2 to be able to upgrade further'
      $NVM_NPM_CMD install -g npm@2
    fi
  fi

  if [ $NVM_IS_0_9 -eq 1 ] || [ $NVM_IS_0_6 -eq 1 ]; then
    nvm_echo '* node v0.6 and v0.9 are unable to upgrade further'
  elif nvm_version_greater 1.1.0 "${NODE_VERSION}"; then
    nvm_echo '* `npm` v4.5.x is the last version that works on `node` versions < v1.1.0'
    $NVM_NPM_CMD install -g npm@4.5
  elif nvm_version_greater 4.0.0 "${NODE_VERSION}"; then
    nvm_echo '* `npm` v5 and higher do not work on `node` versions below v4.0.0'
    $NVM_NPM_CMD install -g npm@4
  elif [ $NVM_IS_0_9 -eq 0 ] && [ $NVM_IS_0_6 -eq 0 ]; then
    local NVM_IS_4_4_OR_BELOW
    NVM_IS_4_4_OR_BELOW=0
    if nvm_version_greater 4.5.0 "${NODE_VERSION}"; then
      NVM_IS_4_4_OR_BELOW=1
    fi

    local NVM_IS_5_OR_ABOVE
    NVM_IS_5_OR_ABOVE=0
    if [ $NVM_IS_4_4_OR_BELOW -eq 0 ] && nvm_version_greater_than_or_equal_to "${NODE_VERSION}" 5.0.0; then
      NVM_IS_5_OR_ABOVE=1
    fi

    local NVM_IS_6_OR_ABOVE
    NVM_IS_6_OR_ABOVE=0
    local NVM_IS_6_2_OR_ABOVE
    NVM_IS_6_2_OR_ABOVE=0
    if [ $NVM_IS_5_OR_ABOVE -eq 1 ] && nvm_version_greater_than_or_equal_to "${NODE_VERSION}" 6.0.0; then
      NVM_IS_6_OR_ABOVE=1
      if nvm_version_greater_than_or_equal_to "${NODE_VERSION}" 6.2.0; then
        NVM_IS_6_2_OR_ABOVE=1
      fi
    fi

    local NVM_IS_9_OR_ABOVE
    NVM_IS_9_OR_ABOVE=0
    local NVM_IS_9_3_OR_ABOVE
    NVM_IS_9_3_OR_ABOVE=0
    if [ $NVM_IS_6_2_OR_ABOVE -eq 1 ] && nvm_version_greater_than_or_equal_to "${NODE_VERSION}" 9.0.0; then
      NVM_IS_9_OR_ABOVE=1
      if nvm_version_greater_than_or_equal_to "${NODE_VERSION}" 9.3.0; then
        NVM_IS_9_3_OR_ABOVE=1
      fi
    fi

    local NVM_IS_10_OR_ABOVE
    NVM_IS_10_OR_ABOVE=0
    if [ $NVM_IS_9_3_OR_ABOVE -eq 1 ] && nvm_version_greater_than_or_equal_to "${NODE_VERSION}" 10.0.0; then
      NVM_IS_10_OR_ABOVE=1
    fi

    if [ $NVM_IS_4_4_OR_BELOW -eq 1 ] || {
      [ $NVM_IS_5_OR_ABOVE -eq 1 ] && nvm_version_greater 5.10.0 "${NODE_VERSION}"; \
    }; then
      nvm_echo '* `npm` `v5.3.x` is the last version that works on `node` 4.x versions below v4.4, or 5.x versions below v5.10, due to `Buffer.alloc`'
      $NVM_NPM_CMD install -g npm@5.3
    elif [ $NVM_IS_4_4_OR_BELOW -eq 0 ] && nvm_version_greater 4.7.0 "${NODE_VERSION}"; then
      nvm_echo '* `npm` `v5.4.1` is the last version that works on `node` `v4.5` and `v4.6`'
      $NVM_NPM_CMD install -g npm@5.4.1
    elif [ $NVM_IS_6_OR_ABOVE -eq 0 ]; then
      nvm_echo '* `npm` `v5.x` is the last version that works on `node` below `v6.0.0`'
      $NVM_NPM_CMD install -g npm@5
    elif \
      { [ $NVM_IS_6_OR_ABOVE -eq 1 ] && [ $NVM_IS_6_2_OR_ABOVE -eq 0 ]; } \
      || { [ $NVM_IS_9_OR_ABOVE -eq 1 ] && [ $NVM_IS_9_3_OR_ABOVE -eq 0 ]; } \
    ; then
      nvm_echo '* `npm` `v6.9` is the last version that works on `node` `v6.0.x`, `v6.1.x`, `v9.0.x`, `v9.1.x`, or `v9.2.x`'
      $NVM_NPM_CMD install -g npm@6.9
    elif [ $NVM_IS_10_OR_ABOVE -eq 0 ]; then
      nvm_echo '* `npm` `v6.x` is the last version that works on `node` below `v10.0.0`'
      $NVM_NPM_CMD install -g npm@6
    else
      nvm_echo '* Installing latest `npm`; if this does not work on your node version, please report a bug!'
      $NVM_NPM_CMD install -g npm
    fi
  fi
  nvm_echo "* npm upgraded to: v$(npm --version 2>/dev/null)"
}
