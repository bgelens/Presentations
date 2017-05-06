# psrp over wsman requires OMI to be installed as OMI enables wsman
firefox https://github.com/Microsoft/omi
# the old and tedious way :)
#wget https://github.com/Microsoft/omi/releases/download/v1.1.0-0/omi-1.1.0.ssl_100.x64.rpm
#yum -y localinstall ./omi-1.1.0.ssl_100.x64.rpm

yum -y install omi

# in case of bad internet
yum localinstall -y ../Packages/omi-1.2.0-35.ulinux.x64.rpm 

systemctl status omid
netstat -anp | grep 598[56]

# configure port 5985 and 5986
psedit /etc/opt/omi/conf/omiserver.conf
systemctl restart omid
netstat -anp | grep 598[56]

# open ports in firewall
/bin/firewall-cmd --zone=public --add-port=5985/tcp --permanent
/bin/firewall-cmd --zone=public --add-port=5986/tcp --permanent
/bin/firewall-cmd --reload

#show cim now works from Windows to Linux

#show cim from Linux to Windows
Get-Command -Noun Cim*
/opt/omi/bin/omicli ei root/cimv2 Win32_OperatingSystem -u administrator -p Welkom01 --auth basic --hostname 172.22.176.51 --port 5985 --encryption http

#fix on windows
/opt/omi/bin/omicli ei root/cimv2 Win32_OperatingSystem -u administrator -p Welkom01 --auth basic --hostname 172.22.176.51 --port 5985 --encryption http

# next to enable inbound PSRP over wsman, the omi psrp provider needs to be installed
firefox https://github.com/PowerShell/psl-omi-provider
#wget https://github.com/PowerShell/psl-omi-provider/releases/download/v.1.0/psrp-1.0.0-0.universal.x64.rpm
#yum -y localinstall ./psrp-1.0.0-0.universal.x64.rpm
yum -y install omi-psrp-server

# in case of bad internet
yum localinstall -y ../Packages/psrp-1.0.0-18.universal.x64.rpm

#show inbound PSRP

# outbound
$PSRPArgs = @{
    ComputerName = '172.22.176.51'
    Credential = [pscredential]::new('Administrator',(ConvertTo-SecureString 'Welkom01' -AsPlainText -Force))
    SessionOption = New-PSSessionOption -NoEncryption
    Authentication = 'Basic'
}
$PSSession = New-PSSession  @PSRPArgs
$PSSession
Import-PSSession -Session $PSSession -Module ServerManager
Get-WindowsFeature | ? installed | select displayname

Invoke-Command -Session $PSSession -ScriptBlock {
    $PSVersionTable
}

# switch to Windows and install 6.0 endpoint
# now create session to endpoint
$PSSession = New-PSSession  @PSRPArgs -ConfigurationName 'powershell.6.0.0-alpha.18'

Invoke-Command -Session $PSSession -ScriptBlock {
    $PSVersionTable
}