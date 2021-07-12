nvm_get_default_packages() {
  local NVM_DEFAULT_PACKAGE_FILE="${NVM_DIR}/default-packages"
  if [ -f "${NVM_DEFAULT_PACKAGE_FILE}" ]; then
    local DEFAULT_PACKAGES
    DEFAULT_PACKAGES=''

    # Read lines from $NVM_DIR/default-packages
    local line
    # ensure a trailing newline
    WORK=$(mktemp -d) || exit $?
    # shellcheck disable=SC2064
    trap "command rm -rf '$WORK'" EXIT
    # shellcheck disable=SC1003
    sed -e '$a\' "${NVM_DEFAULT_PACKAGE_FILE}" > "${WORK}/default-packages"
    while IFS=' ' read -r line; do
      # Skip empty lines.
      [ -n "${line-}" ] || continue

      # Skip comment lines that begin with `#`.
      [ "$(nvm_echo "${line}" | command cut -c1)" != "#" ] || continue

      # Fail on lines that have multiple space-separated words
      case $line in
        *\ *)
          nvm_err "Only one package per line is allowed in the ${NVM_DIR}/default-packages file. Please remove any lines with multiple space-separated values."
          return 1
        ;;
      esac

      DEFAULT_PACKAGES="${DEFAULT_PACKAGES}${line} "
    done < "${WORK}/default-packages"
    echo "${DEFAULT_PACKAGES}" | command xargs
  fi
}

nvm_install_default_packages() {
  nvm_echo "Installing default global packages from ${NVM_DIR}/default-packages..."
  nvm_echo "npm install -g --quiet $1"

  if ! nvm_echo "$1" | command xargs npm install -g --quiet; then
    nvm_err "Failed installing default packages. Please check if your default-packages file or a package in it has problems!"
    return 1
  fi
}
