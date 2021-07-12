# Succeeds if $IOJS_VERSION represents an io.js version that has a
# Solaris binary, fails otherwise.
# Currently, only io.js 3.3.1 has a Solaris binary available, and it's the
# latest io.js version available. The expectation is that any potential io.js
# version later than v3.3.1 will also have Solaris binaries.
nvm_iojs_version_has_solaris_binary() {
  local IOJS_VERSION
  IOJS_VERSION="$1"
  local STRIPPED_IOJS_VERSION
  STRIPPED_IOJS_VERSION="$(nvm_strip_iojs_prefix "${IOJS_VERSION}")"
  if [ "_${STRIPPED_IOJS_VERSION}" = "${IOJS_VERSION}" ]; then
    return 1
  fi

  # io.js started shipping Solaris binaries with io.js v3.3.1
  nvm_version_greater_than_or_equal_to "${STRIPPED_IOJS_VERSION}" v3.3.1
}

# Succeeds if $NODE_VERSION represents a node version that has a
# Solaris binary, fails otherwise.
# Currently, node versions starting from v0.8.6 have a Solaris binary
# available.
nvm_node_version_has_solaris_binary() {
  local NODE_VERSION
  NODE_VERSION="$1"
  # Error out if $NODE_VERSION is actually an io.js version
  local STRIPPED_IOJS_VERSION
  STRIPPED_IOJS_VERSION="$(nvm_strip_iojs_prefix "${NODE_VERSION}")"
  if [ "_${STRIPPED_IOJS_VERSION}" != "_${NODE_VERSION}" ]; then
    return 1
  fi

  # node (unmerged) started shipping Solaris binaries with v0.8.6 and
  # node versions v1.0.0 or greater are not considered valid "unmerged" node
  # versions.
  nvm_version_greater_than_or_equal_to "${NODE_VERSION}" v0.8.6 \
  && ! nvm_version_greater_than_or_equal_to "${NODE_VERSION}" v1.0.0
}

# Succeeds if $VERSION represents a version (node, io.js or merged) that has a
# Solaris binary, fails otherwise.
nvm_has_solaris_binary() {
  local VERSION=$1
  if nvm_is_merged_node_version "${VERSION}"; then
    return 0 # All merged node versions have a Solaris binary
  elif nvm_is_iojs_version "${VERSION}"; then
    nvm_iojs_version_has_solaris_binary "${VERSION}"
  else
    nvm_node_version_has_solaris_binary "${VERSION}"
  fi
}
