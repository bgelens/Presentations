# get DSC packages
#firefox https://github.com/Microsoft/PowerShell-DSC-for-Linux/releases
rpm -Uvh https://github.com/Microsoft/PowerShell-DSC-for-Linux/releases/download/v1.1.1-294/dsc-1.1.1-294.ssl_100.x64.rpm

# in case of bad internet
yum localinstall -y ../Packages/dsc-1.1.1-294.ssl_100.x64.rpm

configuration NGINX {
    # Import-DscResource -ModuleName nx

    nxPackage EPEL {
        Ensure = 'Present'
        Name = 'epel-release'
        PackageManager = 'Yum'
    }

    nxPackage NginX {
        Ensure = 'Present'
        Name = 'nginx'
        PackageManager = 'Yum'
        DependsOn = '[nxPackage]EPEL'
    }

    nxFile MyCoolWebPage {
        Ensure = 'Present'
        DestinationPath = '/usr/share/nginx/html/index.html'
        Contents = '
<center><H1>Hello PSConfEU!</H1></center>
<center><img src="https://pbs.twimg.com/media/CqkeWc1VUAERnq8.jpg"></center>
'
        Force = $true
        DependsOn = '[nxPackage]nginx'
    }

    nxService NginXService {
        Name = 'nginx'
        Controller = 'systemd'
        Enabled = $true
        State = 'Running'
        DependsOn = '[nxFile]MyCoolWebPage'
    }
}

# nx resources in Linux are not in PS ModulePath
Get-DscResource -Module nx
dir /opt/microsoft/dsc/modules/nx/DSCResources
psEdit /opt/microsoft/dsc/modules/nx/DSCResources/MSFT_nxPackageResource/x64/Scripts/3.x/Scripts/nxPackage.py

# not all Dsc cmdlets have been ported
Get-Command -Noun Dsc*

# compile
Get-Command -CommandType Configuration
NGINX

# apply
& /opt/microsoft/dsc/Scripts/StartDscConfiguration.py `
    -configurationmof "$(Get-Location)/NGINX/localhost.mof"

# test
& /opt/microsoft/dsc/Scripts/TestDscConfiguration.py
# get
& /opt/microsoft/dsc/Scripts/GetDscConfiguration.py

# result
firefox http://localhost