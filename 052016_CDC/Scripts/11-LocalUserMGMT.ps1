#region Explore Module
Get-Module -Name Microsoft.PowerShell.LocalAccounts -ListAvailable
Get-Command -Module Microsoft.PowerShell.LocalAccounts
#endregion

#region use LocalAccounts module
New-LocalGroup -Name CDC
New-LocalUser -Name Ben -FullName 'Ben Gelens' -PasswordNeverExpires -Password (ConvertTo-SecureString -String 'Welkom01' -AsPlainText -Force)
Get-LocalUser
Add-LocalGroupMember -Name CDC -Member Ben
Get-LocalGroupMember -Name CDC
Disable-LocalUser -Name Ben
Get-LocalUser -Name Ben
Remove-LocalGroup CDC
Remove-LocalUser Ben
#endregion