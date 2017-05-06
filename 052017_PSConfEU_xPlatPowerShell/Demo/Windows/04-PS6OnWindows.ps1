$uri = 'https://github.com/PowerShell/PowerShell/releases/download/v6.0.0-alpha.18/PowerShell-6.0.0-alpha.18-win10-win2016-x64.msi'
Invoke-WebRequest -Uri $uri -UseBasicParsing -OutFile "~\Demo\PowerShell-6.0.0-alpha.18-win10-win2016-x64.msi"
& "~\Demo\PowerShell-6.0.0-alpha.18-win10-win2016-x64.msi"

# in case of bad internet
& ..\Packages\PowerShell-6.0.0-alpha.18-win10-win2016-x64.msi

# user settings PowerShell extension
# "powershell.developer.powerShellExePath": "C:\\Program Files\\PowerShell\\6.0.0-alpha.18\\powerShell.exe"

$PSVersionTable

Get-PSSessionConfiguration -ErrorAction SilentlyContinue | select Name,PSVersion
ls $pshome -filter *.ps1
. $pshome\Install-PowerShellRemoting.ps1
Get-PSSessionConfiguration -ErrorAction SilentlyContinue | select Name,PSVersion