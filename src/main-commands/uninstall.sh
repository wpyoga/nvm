if [ $# -ne 1 ]; then
  >&2 nvm --help
  return 127
fi

local PATTERN
PATTERN="${1-}"
case "${PATTERN-}" in
  --) ;;
  --lts | 'lts/*')
    VERSION="$(nvm_match_version "lts/*")"
  ;;
  lts/*)
    VERSION="$(nvm_match_version "lts/${PATTERN##lts/}")"
  ;;
  --lts=*)
    VERSION="$(nvm_match_version "lts/${PATTERN##--lts=}")"
  ;;
  *)
    VERSION="$(nvm_version "${PATTERN}")"
  ;;
esac

if [ "_${VERSION}" = "_$(nvm_ls_current)" ]; then
  if nvm_is_iojs_version "${VERSION}"; then
    nvm_err "nvm: Cannot uninstall currently-active io.js version, ${VERSION} (inferred from ${PATTERN})."
  else
    nvm_err "nvm: Cannot uninstall currently-active node version, ${VERSION} (inferred from ${PATTERN})."
  fi
  return 1
fi

if ! nvm_is_version_installed "${VERSION}"; then
  nvm_err "${VERSION} version is not installed..."
  return
fi

local SLUG_BINARY
local SLUG_SOURCE
if nvm_is_iojs_version "${VERSION}"; then
  SLUG_BINARY="$(nvm_get_download_slug iojs binary std "${VERSION}")"
  SLUG_SOURCE="$(nvm_get_download_slug iojs source std "${VERSION}")"
else
  SLUG_BINARY="$(nvm_get_download_slug node binary std "${VERSION}")"
  SLUG_SOURCE="$(nvm_get_download_slug node source std "${VERSION}")"
fi

local NVM_SUCCESS_MSG
if nvm_is_iojs_version "${VERSION}"; then
  NVM_SUCCESS_MSG="Uninstalled io.js $(nvm_strip_iojs_prefix "${VERSION}")"
else
  NVM_SUCCESS_MSG="Uninstalled node ${VERSION}"
fi

local VERSION_PATH
VERSION_PATH="$(nvm_version_path "${VERSION}")"
if ! nvm_check_file_permissions "${VERSION_PATH}"; then
  nvm_err 'Cannot uninstall, incorrect permissions on installation folder.'
  nvm_err 'This is usually caused by running `npm install -g` as root. Run the following commands as root to fix the permissions and then try again.'
  nvm_err
  nvm_err "  chown -R $(whoami) \"$(nvm_sanitize_path "${VERSION_PATH}")\""
  nvm_err "  chmod -R u+w \"$(nvm_sanitize_path "${VERSION_PATH}")\""
  return 1
fi

# Delete all files related to target version.
local CACHE_DIR
CACHE_DIR="$(nvm_cache_dir)"
command rm -rf \
  "${CACHE_DIR}/bin/${SLUG_BINARY}/files" \
  "${CACHE_DIR}/src/${SLUG_SOURCE}/files" \
  "${VERSION_PATH}" 2>/dev/null
nvm_echo "${NVM_SUCCESS_MSG}"

# rm any aliases that point to uninstalled version.
for ALIAS in $(nvm_grep -l "${VERSION}" "$(nvm_alias_path)/*" 2>/dev/null); do
  nvm unalias "$(command basename "${ALIAS}")"
done
