$sessionArgs = @{
    SessionOption = New-PSSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck
    ComputerName = '172.22.176.50'
    Credential = [pscredential]::new('root',(ConvertTo-SecureString -String 'Welkom01' -AsPlainText -Force))
    Authentication = 'Basic'
    UseSSL = $true
}
$pssession = New-PSSession @sessionArgs
$pssession

Invoke-Command -Session $pssession -ScriptBlock {
    ps -aux
}

$pssession | Enter-PSSession
$PSVersionTable
Exit-PSSession # bug!

Import-PSSession -Session $pssession -Module MyTools
Get-OSInfo -Full
Get-LinuxVolume | Sort-Object -Property Available | Select-Object -First 1

Copy-Item -ToSession $pssession -Path "~\demo\01*.ps1" -Destination /tmp
Invoke-Command -Session $pssession -ScriptBlock {
    Get-ChildItem -Path /tmp -Filter *.ps1
}


Invoke-Command -Session $pssession -ScriptBlock {
    New-Item -ItemType File -Path /tmp -Name PSConfEU -Value 'Rocks!' -Force
}
# it works but error
Copy-Item -FromSession $pssession -Path /tmp/PSConfEU -Destination "~\demo"

$pssession | Remove-PSSession