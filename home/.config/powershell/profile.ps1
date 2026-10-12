# Sourced from $PROFILE to set STARSHIP_CONFIG and initialize the Starship prompt.
$env:STARSHIP_CONFIG = Join-Path $PSScriptRoot '../starship/starship.toml'
Invoke-Expression (& starship init powershell | Out-String)
