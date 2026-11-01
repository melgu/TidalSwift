#!/bin/zsh
# Builds tidal and signs it with a development certificate. The Keychain remembers
# "Always Allow" by signing identity, so an ad hoc signed build would prompt after every build.
#
# Usage: ./build.sh [debug|release|install]
# install builds release and copies it to /usr/local/bin, so it runs from any folder
# and later development builds don't change it. Set TIDAL_INSTALL_DIR for another folder.
# Set TIDAL_CODESIGN_IDENTITY if there's more than one "Apple Development" certificate.

set -euo pipefail
cd "$(dirname "$0")"

mode=${1:-debug}
identity=${TIDAL_CODESIGN_IDENTITY:-Apple Development}

case $mode in
	debug|release) configuration=$mode ;;
	install) configuration=release ;;
	*) echo "Usage: $0 [debug|release|install]" >&2; exit 64 ;;
esac

swift build -c "$configuration"
codesign --force --sign "$identity" --identifier de.melgu.TidalSwift.cli ".build/$configuration/tidal"

if [[ $mode == install ]]; then
	destination=${TIDAL_INSTALL_DIR:-/usr/local/bin}
	# Copied rather than linked, keeping the signature. Overwriting the file in place would make macOS
	# kill it at launch, as it caches the signature per file, and break running MCP servers.
	# A new file moved over the old one avoids both.
	cp ".build/release/tidal" "$destination/.tidal.new"
	mv -f "$destination/.tidal.new" "$destination/tidal"
	echo "$destination/tidal"
else
	echo ".build/$configuration/tidal"
fi
