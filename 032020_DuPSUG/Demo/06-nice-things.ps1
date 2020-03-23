# Tab completion build in variables

$ErrorActionPreference = <tab>
$VerbosePreference = <tab>

# ConvertFrom-SecureString

$secureString = Read-Host -AsSecureString
$secureString | ConvertFrom-SecureString -AsPlainText

# xplat clipboard

cat /etc/shells | Set-Clipboard
# past in vs code

Get-Clipboard
