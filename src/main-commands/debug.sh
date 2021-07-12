local OS_VERSION
nvm_is_zsh && setopt local_options shwordsplit
nvm_err "nvm --version: v$(nvm --version)"
if [ -n "${TERM_PROGRAM-}" ]; then
  nvm_err "\$TERM_PROGRAM: ${TERM_PROGRAM}"
fi
nvm_err "\$SHELL: ${SHELL}"
# shellcheck disable=SC2169,SC3028
nvm_err "\$SHLVL: ${SHLVL-}"
nvm_err "whoami: '$(whoami)'"
nvm_err "\${HOME}: ${HOME}"
nvm_err "\${NVM_DIR}: '$(nvm_sanitize_path "${NVM_DIR}")'"
nvm_err "\${PATH}: $(nvm_sanitize_path "${PATH}")"
nvm_err "\$PREFIX: '$(nvm_sanitize_path "${PREFIX}")'"
nvm_err "\${NPM_CONFIG_PREFIX}: '$(nvm_sanitize_path "${NPM_CONFIG_PREFIX}")'"
nvm_err "\$NVM_NODEJS_ORG_MIRROR: '${NVM_NODEJS_ORG_MIRROR}'"
nvm_err "\$NVM_IOJS_ORG_MIRROR: '${NVM_IOJS_ORG_MIRROR}'"
nvm_err "shell version: '$(${SHELL} --version | command head -n 1)'"
nvm_err "uname -a: '$(command uname -a | command awk '{$2=""; print}' | command xargs)'"
nvm_err "checksum binary: '$(nvm_get_checksum_binary 2>/dev/null)'"
if [ "$(nvm_get_os)" = "darwin" ] && nvm_has sw_vers; then
  OS_VERSION="$(sw_vers | command awk '{print $2}' | command xargs)"
elif [ -r "/etc/issue" ]; then
  OS_VERSION="$(command head -n 1 /etc/issue | command sed 's/\\.//g')"
  if [ -z "${OS_VERSION}" ] && [ -r "/etc/os-release" ]; then
    # shellcheck disable=SC1091
    OS_VERSION="$(. /etc/os-release && echo "${NAME}" "${VERSION}")"
  fi
fi
if [ -n "${OS_VERSION}" ]; then
  nvm_err "OS version: ${OS_VERSION}"
fi
if nvm_has "curl"; then
  nvm_err "curl: $(nvm_command_info curl), $(command curl -V | command head -n 1)"
else
  nvm_err "curl: not found"
fi
if nvm_has "wget"; then
  nvm_err "wget: $(nvm_command_info wget), $(command wget -V | command head -n 1)"
else
  nvm_err "wget: not found"
fi

local TEST_TOOLS ADD_TEST_TOOLS
TEST_TOOLS="git grep awk"
ADD_TEST_TOOLS="sed cut basename rm mkdir xargs"
if [ "darwin" != "$(nvm_get_os)" ] && [ "freebsd" != "$(nvm_get_os)" ]; then
  TEST_TOOLS="${TEST_TOOLS} ${ADD_TEST_TOOLS}"
else
  for tool in ${ADD_TEST_TOOLS} ; do
    if nvm_has "${tool}"; then
      nvm_err "${tool}: $(nvm_command_info "${tool}")"
    else
      nvm_err "${tool}: not found"
    fi
  done
fi
for tool in ${TEST_TOOLS} ; do
  local NVM_TOOL_VERSION
  if nvm_has "${tool}"; then
    if command ls -l "$(nvm_command_info "${tool}" | command awk '{print $1}')" | command grep -q busybox; then
      NVM_TOOL_VERSION="$(command "${tool}" --help 2>&1 | command head -n 1)"
    else
      NVM_TOOL_VERSION="$(command "${tool}" --version 2>&1 | command head -n 1)"
    fi
    nvm_err "${tool}: $(nvm_command_info "${tool}"), ${NVM_TOOL_VERSION}"
  else
    nvm_err "${tool}: not found"
  fi
  unset NVM_TOOL_VERSION
done
unset TEST_TOOLS ADD_TEST_TOOLS

local NVM_DEBUG_OUTPUT
for NVM_DEBUG_COMMAND in 'nvm current' 'which node' 'which iojs' 'which npm' 'npm config get prefix' 'npm root -g'; do
  NVM_DEBUG_OUTPUT="$(${NVM_DEBUG_COMMAND} 2>&1)"
  nvm_err "${NVM_DEBUG_COMMAND}: $(nvm_sanitize_path "${NVM_DEBUG_OUTPUT}")"
done
return 42
