Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force
start microsoft-edge:https://github.com/PowerShell/PowerShell/tree/master/demos/SSHRemoting
Invoke-WebRequest -Uri https://github.com/PowerShell/Win32-OpenSSH/releases/download/5_30_2016/OpenSSH-Win64.zip -UseBasicParsing -OutFile ~\desktop\OpenSSH-Win64.zip
Unblock-File ~\desktop\OpenSSH-Win64.zip
Expand-Archive ~\desktop\OpenSSH-Win64.zip -DestinationPath 'C:\Program Files\'
Rename-Item 'C:\Program Files\OpenSSH-Win64' -NewName OpenSSH
Set-Location 'C:\Program Files\OpenSSH'
ls
psedit .\sshd_config
#Subsystem powershell c:\Program Files\PowerShell\6.0.0.9\powershell.exe -sshs -NoLogo -NoProfile
.\install-sshd.ps1
.\ssh-keygen.exe -A
New-NetFirewallRule -Protocol TCP -LocalPort 22 -Direction Inbound -Action Allow -DisplayName SSH
[Environment]::SetEnvironmentVariable( "Path", $env:Path + ';C:\Program Files\OpenSSH', [System.EnvironmentVariableTarget]::Machine)
$env:Path = ([Environment]::GetEnvironmentVariables([EnvironmentVariableTarget]::Machine)).Path
Set-Service -Name sshd -StartupType Automatic
Set-Service -Name ssh-agent -StartupType Automatic
Start-Service sshd
Start-Process 'C:\Program Files\PowerShell\6.0.0.9\powershell.exe'

#config CentOS first before continue
<#
    $Session = New-PSSession -HostName 172.31.255.240 -UserName ben
    $Session | Enter-PSSession
    dir env:
    exit
    Invoke-Command -Session $Session -ScriptBlock {ls /tmp}
    New-Item c:\temp.txt
    Copy-Item -Path C:\temp.txt -Destination /tmp -ToSession $session
#>
#show from CentOS