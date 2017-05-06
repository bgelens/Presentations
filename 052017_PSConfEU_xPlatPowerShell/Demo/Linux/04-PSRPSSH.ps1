psedit /etc/ssh/sshd_config
# subsystem powershell powershell -sshs -NoLogo -NoProfile
systemctl restart sshd

# now configure Windows

$PSSession = New-PSSession -HostName 172.22.176.51 -UserName Administrator
$PSSession

# show inbound key based