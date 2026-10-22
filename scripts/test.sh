#!/usr/bin/env bash
# Command Line Tools ship swift-testing but SwiftPM doesn't load its macro plugin by default.
set -euo pipefail
cd "$(dirname "$0")/.."
PLUGINS="$(dirname "$(xcrun --find swift-frontend)")/../lib/swift/host/plugins/testing"
exec swift test -Xswiftc -plugin-path -Xswiftc "$PLUGINS" "$@"
