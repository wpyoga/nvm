command rm -f "${NVM_DIR}/v*" "$(nvm_version_dir)" 2>/dev/null
nvm_echo 'nvm cache cleared.'
