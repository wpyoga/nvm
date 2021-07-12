# Node Version Manager
# Implemented as a POSIX-compliant function
# Should work on sh, dash, bash, ksh, zsh
# To use source this file from your bash profile
#
# Implemented by Tim Caswell <tim@creationix.com>
# with much bash help from Matthew Ranney

# "local" warning, quote expansion warning, sed warning, `local` warning
# shellcheck disable=SC2039,SC2016,SC2001,SC3043
{ # this ensures the entire script is downloaded #

# shellcheck disable=SC3028
NVM_SCRIPT_SOURCE="$_"

# @MERGE
. src/functions/util.sh

# @MERGE
. src/functions/update.sh

# Make zsh glob matching behave same as bash
# This fixes the "zsh: no matches found" errors
if [ -z "${NVM_CD_FLAGS-}" ]; then
  export NVM_CD_FLAGS=''
fi
if nvm_is_zsh; then
  NVM_CD_FLAGS="-q"
fi

# Auto detect the NVM_DIR when not set
if [ -z "${NVM_DIR-}" ]; then
  # shellcheck disable=SC2128
  if [ -n "${BASH_SOURCE-}" ]; then
    # shellcheck disable=SC2169,SC3054
    NVM_SCRIPT_SOURCE="${BASH_SOURCE[0]}"
  fi
  NVM_DIR="$(nvm_cd ${NVM_CD_FLAGS} "$(dirname "${NVM_SCRIPT_SOURCE:-$0}")" >/dev/null && \pwd)"
  export NVM_DIR
else
  # https://unix.stackexchange.com/a/198289
  case $NVM_DIR in
    *[!/]*/)
      NVM_DIR="${NVM_DIR%"${NVM_DIR##*[!/]}"}"
      export NVM_DIR
      nvm_err "Warning: \$NVM_DIR should not have trailing slashes"
    ;;
  esac
fi
unset NVM_SCRIPT_SOURCE 2>/dev/null

# @MERGE
. src/functions/search.sh

# @MERGE
. src/functions/version.sh

# @MERGE
. src/functions/path.sh

# @MERGE
. src/functions/colors.sh

# @MERGE
. src/functions/alias.sh

# @MERGE
. src/functions/prefix.sh

# @MERGE
. src/functions/iojs.sh

# @MERGE
. src/functions/nvm_ls.sh

# @MERGE
. src/functions/nvm_ls_remote.sh

# @MERGE
. src/functions/checksum.sh

# @MERGE
. src/functions/misc-1.sh

# @MERGE
. src/functions/environment.sh

# @MERGE
. src/functions/misc-2.sh

# @MERGE
. src/functions/install.sh

# @MERGE
. src/functions/misc-3.sh

# @MERGE
. src/functions/solaris.sh

# @MERGE
. src/functions/misc-4.sh

# @MERGE
. src/nvm-function.sh

# @MERGE
. src/functions/packages.sh

# @MERGE
. src/functions/misc-5.sh

nvm_process_parameters "$@"

} # this ensures the entire script is downloaded #
