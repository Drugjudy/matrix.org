#!/bin/bash -eux

# update_docs.sh: regenerates the autogenerated files on the matrix.org site.
# At present this includes:
#   * the spec intro and appendices
#   * the guides and howtos
#   * the swagger UI for the API
#   * 'Unstable' versions of the spec docs
#
# Note that the historical versions of the CS spec and swagger, and the spec
# index, are generated manually within matrix-doc and then *committed to git*.

# Note that this file is world-readable unless someone plays some .htaccess hijinks

SELF="${BASH_SOURCE[0]}"
if [[ "${SELF}" != /* ]]; then
  SELF="$(pwd)/${SELF}"
fi
SELF="${SELF/\/.\///}"
cd "$(dirname "$(dirname "${SELF}")")"

SITE_BASE="$(pwd)"

# grab and unpack the latest matrix-docs build from buildkite
rm -rf assets.tar.gz assets
scripts/fetch-buildkite-artifact matrix-dot-org matrix-doc assets.tar.gz
tar -xzf assets.tar.gz

# copy the swagger UI into place
rm -fr unstyled_docs/api/client-server
mkdir -p unstyled_docs/api/client-server/json
cp -r swagger-ui/dist/* unstyled_docs/api/client-server/
(cd unstyled_docs && patch -p0) <scripts/swagger-ui.patch

# and the unstable spec docs, but not the spec index (because we want to keep
# the git version, which points to a specific c-s version)
rm assets/spec/index.html || true
cp -ar assets/spec unstyled_docs

# add a link to the stable swagger doc
ln -s ../../../spec/client_server/latest.json unstyled_docs/api/client-server/json/api-docs.json

# copy the unstyled docs and add the jekyll styling
rm -rf content/docs
cp -r unstyled_docs content/docs
find "content/docs" -name '*.html' -type f |
    xargs "./scripts/add-matrix-org-stylings.pl" "./jekyll/_includes"

