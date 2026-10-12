# Sourced from $PROFILE to set STARSHIP_CONFIG and initialize the Starship prompt.
$env:STARSHIP_CONFIG = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../../../shared/config/starship/starship.toml') -ErrorAction Stop).Path
Invoke-Expression (& starship init powershell | Out-String)
