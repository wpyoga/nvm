if [ $# -ne 0 ]; then
  >&2 nvm --help
  return 127
fi

nvm_install_latest_npm
