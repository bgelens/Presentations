$CimArgs = @{
    SessionOption = New-CimSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck -UseSsl
    ComputerName = '172.22.176.250'
    Authentication = 'Basic'
    Credential = [pscredential]::new('root',(ConvertTo-SecureString 'Welkom01' -AsPlainText -Force))
}
$CimSession = New-CimSession @CimArgs
$CimSession


# onboard the linux node
[DscLocalConfigurationManager()]
configuration LCM {
    node 172.22.176.250 {
        Settings
        {
            RefreshMode          = 'Pull'
            RefreshFrequencyMins = 30 
            RebootNodeIfNeeded   = $true
        }

        ConfigurationRepositoryWeb PSConfEU-PullSrv
        {
            ServerURL          = 'http://172.22.176.200:8080/PSDSCPullServer.svc'
            RegistrationKey    = '140a952b-b9d6-406b-b416-e0f759c9c0e4'
            AllowUnsecureConnection = $true
            ConfigurationNames = @('LinuxDemo')
        }   

        ReportServerWeb PSConfEU-PullSrv
        {
            ServerURL       = 'http://172.22.176.200:8080/PSDSCPullServer.svc'
            RegistrationKey = '140a952b-b9d6-406b-b416-e0f759c9c0e4'
            AllowUnsecureConnection = $true
        }
    }
}

LCM

Set-DscLocalConfigurationManager -CimSession $CimSession -Path .\LCM -Verbose
Get-DscLocalConfigurationManager -CimSession $CimSession

Get-DscLocalConfigurationManager -CimSession $CimSession | select -expand ConfigurationDownloadManagers

# add a configuration to the pull server

configuration NGINX {
    Import-DscResource -ModuleName nx

    node LinuxDemo {
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
}
$Compile = NGINX -OutputPath "$env:PROGRAMFILES\WindowsPowerShell\DscService\Configuration"
$Compile
New-DscChecksum -Path $Compile.PSParentPath
Get-ChildItem "$env:PROGRAMFILES\WindowsPowerShell\DscService\Configuration"

# update the client
Update-DscConfiguration -CimSession $CimSession -Wait -Verbose

# Get, Test
Test-DscConfiguration -CimSession $CimSession
Get-DscConfiguration -CimSession $CimSession

# result :)
start -FilePath http://172.22.176.250