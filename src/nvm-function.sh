nvm() {
  if [ $# -lt 1 ]; then
    nvm --help
    return
  fi

  local DEFAULT_IFS
  DEFAULT_IFS=" $(nvm_echo t | command tr t \\t)
"
  if [ "${-#*e}" != "$-" ]; then
    set +e
    local EXIT_CODE
    IFS="${DEFAULT_IFS}" nvm "$@"
    EXIT_CODE=$?
    set -e
    return $EXIT_CODE
  elif [ "${IFS}" != "${DEFAULT_IFS}" ]; then
    IFS="${DEFAULT_IFS}" nvm "$@"
    return $?
  fi

  local i
  for i in "$@"
  do
    case $i in
      --) break ;;
      '-h'|'help'|'--help')
        # @MERGE
        . src/main-commands/help.sh
      ;;
    esac
  done

  local COMMAND
  COMMAND="${1-}"
  shift

  # initialize local variables
  local VERSION
  local ADDITIONAL_PARAMETERS

  case $COMMAND in
    "cache")
      # @MERGE
      . src/main-commands/cache.sh
    ;;

    "debug")
      # @MERGE
      . src/main-commands/debug.sh
    ;;

    "install" | "i")
      # @MERGE
      . src/main-commands/install.sh
    ;;
    "uninstall")
      # @MERGE
      . src/main-commands/uninstall.sh
    ;;
    "deactivate")
      # @MERGE
      . src/main-commands/deactivate.sh
    ;;
    "use")
      # @MERGE
      . src/main-commands/use.sh
    ;;
    "run")
      # @MERGE
      . src/main-commands/run.sh
    ;;
    "exec")
      # @MERGE
      . src/main-commands/exec.sh
    ;;
    "ls" | "list")
      # @MERGE
      . src/main-commands/list.sh
    ;;
    "ls-remote" | "list-remote")
      # @MERGE
      . src/main-commands/list-remote.sh
    ;;
    "current")
      nvm_version current
    ;;
    "which")
      # @MERGE
      . src/main-commands/which.sh
    ;;
    "alias")
      # @MERGE
      . src/main-commands/alias.sh
    ;;
    "unalias")
      # @MERGE
      . src/main-commands/unalias.sh
    ;;
    "install-latest-npm")
      # @MERGE
      . src/main-commands/install-latest-npm.sh
    ;;
    "reinstall-packages" | "copy-packages")
      # @MERGE
      . src/main-commands/reinstall-packages.sh
    ;;
    "clear-cache")
      # @MERGE
      . src/main-commands/clear-cache.sh
    ;;
    "version")
      # @MERGE
      . src/main-commands/version.sh
    ;;
    "version-remote")
      # @MERGE
      . src/main-commands/version-remote.sh
    ;;
    "--version" | "-v")
      # @MERGE
      . src/main-commands/dashdash-version.sh
    ;;
    "unload")
      # @MERGE
      . src/main-commands/unload.sh
    ;;
    "set-colors")
      # @MERGE
      . src/main-commands/set-colors.sh
    ;;
    *)
      >&2 nvm --help
      return 127
    ;;
  esac
}
