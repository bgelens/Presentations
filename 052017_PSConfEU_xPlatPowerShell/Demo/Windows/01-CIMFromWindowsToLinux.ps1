$cimsessionArgs = @{
    SessionOption = New-CimSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck -UseSsl
    ComputerName = '172.22.176.50'
    Credential = [pscredential]::new('root',(ConvertTo-SecureString -String 'Welkom01' -AsPlainText -Force))
    Authentication = 'Basic'
}
$cimsession = New-CimSession @cimsessionArgs
$cimsession
Get-CimInstance -CimSession $cimsession -Namespace root/omi -ClassName OMI_Identify
$cimsession | Remove-CimSession