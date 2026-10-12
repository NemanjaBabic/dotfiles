#!/usr/bin/env bash
set -eu

# shellcheck source=tests/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

POWERSHELL_BIN=${POWERSHELL_BIN:-pwsh}
command -v "$POWERSHELL_BIN" >/dev/null 2>&1 || fail "PowerShell runtime not found (set POWERSHELL_BIN)"

"$POWERSHELL_BIN" -NoLogo -NoProfile -File "$ROOT/tests/herdr-bootstrap.test.ps1" \
  -BootstrapPath "$ROOT/windows/bootstrap-windows.ps1" || fail "Herdr Windows bootstrap behavior"

pass "Herdr bootstrap validates configuration before changing environment variables"
