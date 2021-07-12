local EXIT_CODE
nvm_set_colors "${1-}"
EXIT_CODE=$?
if [ "$EXIT_CODE" -eq 17 ]; then
  >&2 nvm --help
  nvm_echo
  nvm_err_with_colors "\033[1;37mPlease pass in five \033[1;31mvalid color codes\033[1;37m. Choose from: rRgGbBcCyYmMkKeW\033[0m"
fi
