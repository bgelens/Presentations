wget https://packages.microsoft.com/config/rhel/7/prod.repo -O /etc/yum.repos.d/microsoft.repo
yum repolist
yum --disablerepo="*" --enablerepo="packages-microsoft-com-prod" list available
# install powershell. Not requirement for DSC On Linux
yum install -y powershell

# install OMI. Brings CIMOM + WSMAN
yum install -y omi
systemctl status omid

# have WSMAN listen on well known ports
netstat -anp | grep 598[56]
vi /etc/opt/omi/conf/omiserver.conf
systemctl restart omid
netstat -anp | grep 598[56]

# open firewall
/bin/firewall-cmd --zone=public --add-port=5985/tcp --permanent
/bin/firewall-cmd --zone=public --add-port=5986/tcp --permanent
/bin/firewall-cmd --reload

# install dsc
rpm -Uvh https://github.com/Microsoft/PowerShell-DSC-for-Linux/releases/download/v1.1.1-294/dsc-1.1.1-294.ssl_100.x64.rpm

# LCM config
python /opt/microsoft/dsc/Scripts/GetDscLocalConfigurationManager.py

# explore resources
ls /opt/microsoft/dsc/modules/nx/DSCResources
more /opt/microsoft/dsc/modules/nx/DSCResources/MSFT_nxPackageResource/x64/Scripts/3.x/Scripts/nxPackage.py

# compile and apply locally using PowerShell v6!
#configuration EPEL {
#    nxPackage EPEL {
#        Ensure = 'Present'
#        Name = 'epel-release'
#        PackageManager = 'Yum'
#    }
#}
#
#Get-Command -CommandType Configuration
#
#EPEL
#
## enact
#& /opt/microsoft/dsc/Scripts/StartDscConfiguration.py `
#    -configurationmof "$(Get-Location)/EPEL/localhost.mof"
#
## test
#& /opt/microsoft/dsc/Scripts/TestDscConfiguration.py
#
## get
#& /opt/microsoft/dsc/Scripts/GetDscConfiguration.py