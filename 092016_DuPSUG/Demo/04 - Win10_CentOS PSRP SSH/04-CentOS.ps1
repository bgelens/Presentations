Start-Process bash -ArgumentList '-c tmux'
<#
    ssh ben@172.31.255.240
    sudo vi /etc/ssh/sshd_config
    Subsystem       powershell /usr/bin/powershell -sshs -NoLogo -NoProfile
    sudo systemctl restart sshd
    powershell
    New-PSSession -HostName localhost -UserName ben
#>
#show from Windows first
<#
    $session = New-PSSession -HostName 172.31.255.242 -UserName ben
    $session | Enter-PSSession
    dir env:
    exit
    Invoke-Command -Session $session -ScriptBlock {Get-Service wuauserv}
    touch temp2.txt
    Copy-Item -Path ./temp2.txt -Destination c:\ -ToSession $session
#>