Clear-Host
Write-Verbose -Message '$Session = New-PSSession' -Verbose
$Session = New-PSSession
Read-Host
Clear-Host
Write-Verbose -Message 'Showing Session' -Verbose
$Session
Read-Host
Clear-Host
Write-Verbose -Message 'Invoke-Command -Session $Session -ScriptBlock {$PSVersionTable}' -Verbose
Invoke-Command -Session $Session -ScriptBlock {$PSVersionTable | Out-String}
Read-Host
Clear-Host
Write-Verbose -Message 'Session Configuration' -Verbose
$Session.ConfigurationName
$Session | Remove-PSSession
Read-Host
Clear-Host
Write-Verbose -Message 'Get-PSSessionConfiguration' -Verbose
Get-PSSessionConfiguration | Out-String
Read-Host
Write-Verbose -Message 'No version 6 endpoints!' -Verbose
Write-Verbose -Message 'Also no Workflow support' -Verbose
Read-Host
Clear-Host
Write-Verbose -Message 'Registering Endpoint for v6' -Verbose
Write-Verbose -Message 'ls $pshome -filter *.ps1' -Verbose
ls $pshome -filter *.ps1 | Out-String
Read-Host
Write-Verbose -Message '. $pshome\Install-PowerShellRemoting.ps1' -Verbose
. $pshome\Install-PowerShellRemoting.ps1 | Out-String
Read-Host
Clear-Host
Write-Verbose -Message 'Creating new session to v6 endpoint' -Verbose
Write-Verbose -Message '$Session = New-PSSession -ConfigurationName powershell.6.0.0-alpha.9' -Verbose
$Session = New-PSSession -ConfigurationName powershell.6.0.0-alpha.9
Read-Host
Write-Verbose -Message 'Showing Session' -Verbose
$Session
Read-Host
Write-Verbose -Message 'Invoke-Command -Session $Session -ScriptBlock {$PSVersionTable}' -Verbose
Invoke-Command -Session $Session -ScriptBlock {$PSVersionTable | Out-String}
#cleanup
$null = Unregister-PSSessionConfiguration -Name powershell.6.0.0-alpha.9