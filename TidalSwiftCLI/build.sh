#!/bin/zsh
# Builds tidal and signs it with a development certificate. The Keychain remembers
# "Always Allow" by signing identity, so an ad hoc signed build would prompt after every build.
#
# Usage: ./build.sh [debug|release]
# Set TIDAL_CODESIGN_IDENTITY if there's more than one "Apple Development" certificate.

set -euo pipefail
cd "$(dirname "$0")"

configuration=${1:-debug}
identity=${TIDAL_CODESIGN_IDENTITY:-Apple Development}

swift build -c "$configuration"
codesign --force --sign "$identity" --identifier de.melgu.TidalSwift.cli ".build/$configuration/tidal"
echo ".build/$configuration/tidal"
