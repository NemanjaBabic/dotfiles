$env:STARSHIP_CONFIG = Join-Path $PSScriptRoot '../starship/starship.toml'
Invoke-Expression (& starship init powershell | Out-String)
