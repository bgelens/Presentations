configuration NGINX {
    nxPackage nginx {
        Ensure = 'Present'
        Name = 'nginx-core'
        PackageManager = 'apt'
    }
    
    nxFile MyCoolWebPage {
        Ensure = 'Present'
        DestinationPath = '/var/www/html/index.nginx-debian.html'
        Contents = '
<center><H1>Hello DuPSUG!</H1></center>
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
NGINX
& sudo /opt/microsoft/dsc/Scripts/StartDscConfiguration.py `
    -configurationmof "$(Get-Location)/NGINX/localhost.mof"
& sudo /opt/microsoft/dsc/Scripts/GetDscConfiguration.py
firefox http://localhost