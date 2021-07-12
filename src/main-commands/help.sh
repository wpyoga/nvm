NVM_NO_COLORS=""
for j in "$@"; do
  if [ "${j}" = '--no-colors' ]; then
    NVM_NO_COLORS="${j}"
    break
  fi
done

local INITIAL_COLOR_INFO
local RED_INFO
local GREEN_INFO
local BLUE_INFO
local CYAN_INFO
local MAGENTA_INFO
local YELLOW_INFO
local BLACK_INFO
local GREY_WHITE_INFO

if [ -z "${NVM_NO_COLORS-}"  ] && nvm_has_colors; then
  INITIAL_COLOR_INFO='\033[0;32m g\033[0m \033[0;34m b\033[0m \033[0;33m y\033[0m \033[0;31m r\033[0m \033[0;37m e\033[0m'
  RED_INFO='\033[0;31m r\033[0m/\033[1;31mR\033[0m = \033[0;31mred\033[0m / \033[1;31mbold red\033[0m'
  GREEN_INFO='\033[0;32m g\033[0m/\033[1;32mG\033[0m = \033[0;32mgreen\033[0m / \033[1;32mbold green\033[0m'
  BLUE_INFO='\033[0;34m b\033[0m/\033[1;34mB\033[0m = \033[0;34mblue\033[0m / \033[1;34mbold blue\033[0m'
  CYAN_INFO='\033[0;36m c\033[0m/\033[1;36mC\033[0m = \033[0;36mcyan\033[0m / \033[1;36mbold cyan\033[0m'
  MAGENTA_INFO='\033[0;35m m\033[0m/\033[1;35mM\033[0m = \033[0;35mmagenta\033[0m / \033[1;35mbold magenta\033[0m'
  YELLOW_INFO='\033[0;33m y\033[0m/\033[1;33mY\033[0m = \033[0;33myellow\033[0m / \033[1;33mbold yellow\033[0m'
  BLACK_INFO='\033[0;30m k\033[0m/\033[1;30mK\033[0m = \033[0;30mblack\033[0m / \033[1;30mbold black\033[0m'
  GREY_WHITE_INFO='\033[0;37m e\033[0m/\033[1;37mW\033[0m = \033[0;37mlight grey\033[0m / \033[1;37mwhite\033[0m'
else
  INITIAL_COLOR_INFO='gbYre'
  RED_INFO='r/R = red / bold red'
  GREEN_INFO='g/G = green / bold green'
  BLUE_INFO='b/B = blue / bold blue'
  CYAN_INFO='c/C = cyan / bold cyan'
  MAGENTA_INFO='m/M = magenta / bold magenta'
  YELLOW_INFO='y/Y = yellow / bold yellow'
  BLACK_INFO='k/K = black / bold black'
  GREY_WHITE_INFO='e/W = light grey / white'
fi

local NVM_IOJS_PREFIX
NVM_IOJS_PREFIX="$(nvm_iojs_prefix)"
local NVM_NODE_PREFIX
NVM_NODE_PREFIX="$(nvm_node_prefix)"
NVM_VERSION="$(nvm --version)"
nvm_echo
nvm_echo "Node Version Manager (v${NVM_VERSION})"
nvm_echo
nvm_echo 'Note: <version> refers to any version-like string nvm understands. This includes:'
nvm_echo '  - full or partial version numbers, starting with an optional "v" (0.10, v0.1.2, v1)'
nvm_echo "  - default (built-in) aliases: ${NVM_NODE_PREFIX}, stable, unstable, ${NVM_IOJS_PREFIX}, system"
nvm_echo '  - custom aliases you define with `nvm alias foo`'
nvm_echo
nvm_echo ' Any options that produce colorized output should respect the `--no-colors` option.'
nvm_echo
nvm_echo 'Usage:'
nvm_echo '  nvm --help                                  Show this message'
nvm_echo '    --no-colors                               Suppress colored output'
nvm_echo '  nvm --version                               Print out the installed version of nvm'
nvm_echo '  nvm install [<version>]                     Download and install a <version>. Uses .nvmrc if available and version is omitted.'
nvm_echo '   The following optional arguments, if provided, must appear directly after `nvm install`:'
nvm_echo '    -s                                        Skip binary download, install from source only.'
nvm_echo '    -b                                        Skip source download, install from binary only.'
nvm_echo '    --reinstall-packages-from=<version>       When installing, reinstall packages installed in <node|iojs|node version number>'
nvm_echo '    --lts                                     When installing, only select from LTS (long-term support) versions'
nvm_echo '    --lts=<LTS name>                          When installing, only select from versions for a specific LTS line'
nvm_echo '    --skip-default-packages                   When installing, skip the default-packages file if it exists'
nvm_echo '    --latest-npm                              After installing, attempt to upgrade to the latest working npm on the given node version'
nvm_echo '    --no-progress                             Disable the progress bar on any downloads'
nvm_echo '    --alias=<name>                            After installing, set the alias specified to the version specified. (same as: nvm alias <name> <version>)'
nvm_echo '    --default                                 After installing, set default alias to the version specified. (same as: nvm alias default <version>)'
nvm_echo '  nvm uninstall <version>                     Uninstall a version'
nvm_echo '  nvm uninstall --lts                         Uninstall using automatic LTS (long-term support) alias `lts/*`, if available.'
nvm_echo '  nvm uninstall --lts=<LTS name>              Uninstall using automatic alias for provided LTS line, if available.'
nvm_echo '  nvm use [<version>]                         Modify PATH to use <version>. Uses .nvmrc if available and version is omitted.'
nvm_echo '   The following optional arguments, if provided, must appear directly after `nvm use`:'
nvm_echo '    --silent                                  Silences stdout/stderr output'
nvm_echo '    --lts                                     Uses automatic LTS (long-term support) alias `lts/*`, if available.'
nvm_echo '    --lts=<LTS name>                          Uses automatic alias for provided LTS line, if available.'
nvm_echo '  nvm exec [<version>] [<command>]            Run <command> on <version>. Uses .nvmrc if available and version is omitted.'
nvm_echo '   The following optional arguments, if provided, must appear directly after `nvm exec`:'
nvm_echo '    --silent                                  Silences stdout/stderr output'
nvm_echo '    --lts                                     Uses automatic LTS (long-term support) alias `lts/*`, if available.'
nvm_echo '    --lts=<LTS name>                          Uses automatic alias for provided LTS line, if available.'
nvm_echo '  nvm run [<version>] [<args>]                Run `node` on <version> with <args> as arguments. Uses .nvmrc if available and version is omitted.'
nvm_echo '   The following optional arguments, if provided, must appear directly after `nvm run`:'
nvm_echo '    --silent                                  Silences stdout/stderr output'
nvm_echo '    --lts                                     Uses automatic LTS (long-term support) alias `lts/*`, if available.'
nvm_echo '    --lts=<LTS name>                          Uses automatic alias for provided LTS line, if available.'
nvm_echo '  nvm current                                 Display currently activated version of Node'
nvm_echo '  nvm ls [<version>]                          List installed versions, matching a given <version> if provided'
nvm_echo '    --no-colors                               Suppress colored output'
nvm_echo '    --no-alias                                Suppress `nvm alias` output'
nvm_echo '  nvm ls-remote [<version>]                   List remote versions available for install, matching a given <version> if provided'
nvm_echo '    --lts                                     When listing, only show LTS (long-term support) versions'
nvm_echo '    --lts=<LTS name>                          When listing, only show versions for a specific LTS line'
nvm_echo '    --no-colors                               Suppress colored output'
nvm_echo '  nvm version <version>                       Resolve the given description to a single local version'
nvm_echo '  nvm version-remote <version>                Resolve the given description to a single remote version'
nvm_echo '    --lts                                     When listing, only select from LTS (long-term support) versions'
nvm_echo '    --lts=<LTS name>                          When listing, only select from versions for a specific LTS line'
nvm_echo '  nvm deactivate                              Undo effects of `nvm` on current shell'
nvm_echo '    --silent                                  Silences stdout/stderr output'
nvm_echo '  nvm alias [<pattern>]                       Show all aliases beginning with <pattern>'
nvm_echo '    --no-colors                               Suppress colored output'
nvm_echo '  nvm alias <name> <version>                  Set an alias named <name> pointing to <version>'
nvm_echo '  nvm unalias <name>                          Deletes the alias named <name>'
nvm_echo '  nvm install-latest-npm                      Attempt to upgrade to the latest working `npm` on the current node version'
nvm_echo '  nvm reinstall-packages <version>            Reinstall global `npm` packages contained in <version> to current version'
nvm_echo '  nvm unload                                  Unload `nvm` from shell'
nvm_echo '  nvm which [current | <version>]             Display path to installed node version. Uses .nvmrc if available and version is omitted.'
nvm_echo '    --silent                                  Silences stdout/stderr output when a version is omitted'
nvm_echo '  nvm cache dir                               Display path to the cache directory for nvm'
nvm_echo '  nvm cache clear                             Empty cache directory for nvm'
nvm_echo '  nvm set-colors [<color codes>]              Set five text colors using format "yMeBg". Available when supported.'
nvm_echo '                                               Initial colors are:'
nvm_echo_with_colors "                                                  ${INITIAL_COLOR_INFO}"
nvm_echo '                                               Color codes:'
nvm_echo_with_colors "                                                ${RED_INFO}"
nvm_echo_with_colors "                                                ${GREEN_INFO}"
nvm_echo_with_colors "                                                ${BLUE_INFO}"
nvm_echo_with_colors "                                                ${CYAN_INFO}"
nvm_echo_with_colors "                                                ${MAGENTA_INFO}"
nvm_echo_with_colors "                                                ${YELLOW_INFO}"
nvm_echo_with_colors "                                                ${BLACK_INFO}"
nvm_echo_with_colors "                                                ${GREY_WHITE_INFO}"
nvm_echo
nvm_echo 'Example:'
nvm_echo '  nvm install 8.0.0                     Install a specific version number'
nvm_echo '  nvm use 8.0                           Use the latest available 8.0.x release'
nvm_echo '  nvm run 6.10.3 app.js                 Run app.js using node 6.10.3'
nvm_echo '  nvm exec 4.8.3 node app.js            Run `node app.js` with the PATH pointing to node 4.8.3'
nvm_echo '  nvm alias default 8.1.0               Set default node version on a shell'
nvm_echo '  nvm alias default node                Always default to the latest available node version on a shell'
nvm_echo
nvm_echo '  nvm install node                      Install the latest available version'
nvm_echo '  nvm use node                          Use the latest version'
nvm_echo '  nvm install --lts                     Install the latest LTS version'
nvm_echo '  nvm use --lts                         Use the latest LTS version'
nvm_echo
nvm_echo '  nvm set-colors cgYmW                  Set text colors to cyan, green, bold yellow, magenta, and white'
nvm_echo
nvm_echo 'Note:'
nvm_echo '  to remove, delete, or uninstall nvm - just remove the `$NVM_DIR` folder (usually `~/.nvm`)'
nvm_echo
return 0;
