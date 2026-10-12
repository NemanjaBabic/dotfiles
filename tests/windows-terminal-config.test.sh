#!/usr/bin/env bash
set -eu

# shellcheck source=tests/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

POWERSHELL_BIN=${POWERSHELL_BIN:-pwsh}
command -v "$POWERSHELL_BIN" >/dev/null 2>&1 || fail "PowerShell runtime not found (set POWERSHELL_BIN)"

"$POWERSHELL_BIN" -NoLogo -NoProfile -File "$ROOT/tests/windows-terminal-config.test.ps1" \
  -RepositoryRoot "$ROOT" || fail "Windows terminal config behavior"

pass "Windows terminal defaults and profile normalization are consistent"
