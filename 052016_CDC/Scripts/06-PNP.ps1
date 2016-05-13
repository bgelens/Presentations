#region pssession
$PassWord = (ConvertTo-SecureString -String 'P@ssw0rd!' -AsPlainText -Force)
$SessionArgs = @{
    ComputerName = '10.10.10.20'
    Credential = [pscredential]::new('Administrator',$PassWord)
}
$PNPSession = New-PSSession @SessionArgs
#endregion

#region PNP device management
$PNPSession | Enter-PSSession
Get-Module -Name PnpDevice -ListAvailable
Get-Command -Module PnpDevice

Get-PnpDevice
Get-PnpDevice -FriendlyName 'Volume Manager'
Get-PnpDevice -FriendlyName 'Volume Manager' | Get-PnpDeviceProperty
Get-PnpDevice -FriendlyName 'Volume Manager' | Disable-PnpDevice
Get-PnpDevice -FriendlyName 'Volume Manager' | Enable-PnpDevice
Exit-PSSession
#endregion