#https://github.com/PowerShell/Win32-OpenSSH/releases
$uri = 'https://github.com/PowerShell/Win32-OpenSSH/releases/download/v0.0.11.0/OpenSSH-Win64.zip'
Invoke-WebRequest -UseBasicParsing -Uri $uri -OutFile "~\Demo\OpenSSH-Win64.zip"
Unblock-File -Path "~\Demo\OpenSSH-Win64.zip"
Expand-Archive -Path "~\Demo\OpenSSH-Win64.zip" -DestinationPath 'c:\Program Files'

# in case of bad internet
Expand-Archive -Path "~\Packages\OpenSSH-Win64.zip" -DestinationPath 'c:\Program Files'

Rename-Item -Path 'C:\Program Files\OpenSSH-Win64' -NewName 'OpenSSH'

$SysEnv = Get-CimInstance -ClassName Win32_Environment -Filter 'SystemVariable=True AND Name="Path"'
$SysEnv.VariableValue = $SysEnv.VariableValue + ";C:\Program Files\OpenSSH"
$SysEnv | Set-CimInstance

Set-Location -Path 'C:\Program Files\OpenSSH'
Get-ChildItem
code .\sshd_config
# Subsystem powershell c:\Program Files\PowerShell\6.0.0-alpha.18\powershell.exe -sshs -NoLogo -NoProfile
.\install-sshd.ps1
.\ssh-keygen.exe -A

# run in onbox PS 5.1
powershell -command {
    New-NetFirewallRule -Protocol TCP -LocalPort 22 -Direction Inbound -Action Allow -DisplayName ssh
}
Set-Service -Name sshd -StartupType Automatic
Set-Service -Name ssh-agent -StartupType Automatic
Start-Service -Name sshd

$env:Path = $env:Path + ";C:\Program Files\OpenSSH"

# show inbound

# key file
$password = Read-Host -AsSecureString -Prompt "Password"
New-LocalUser -Name ben -AccountNeverExpires -Password $password
Add-LocalGroupMember -Group Administrators -Member ben
runas /user:ben cmd.exe
#run in cmd for now
# ssh-keygen.exe
# scp.exe C:\Users\ben\.ssh\id_rsa.pub ben@172.22.176.50:/home/ben/.ssh/authorized_keys
.\install-sshlsa.ps1 #registers DLL to work with local / workgroup accounts. Requires reboot. 
# Is fixed in 0.0.12.0 OpenSSH release but I had demo issues with this release :(
Restart-Computer -Force

New-PSSession -HostName 172.22.176.50 -UserName ben -KeyFilePath C:\Users\ben\.ssh\id_rsa

$Cred = [pscredential]::new('ben',(ConvertTo-SecureString 'Welkom01' -AsPlainText -Force))
etsn . -Credential $cred -ConfigurationName 'powershell.6.0.0-alpha.18'
whoami
New-PSSession -HostName 172.22.176.50 -UserName ben