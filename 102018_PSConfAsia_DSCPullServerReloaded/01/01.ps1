#region connect with edb pull server
$edbsession | Enter-PSSession
#endregion

#region show os version
[environment]::OSVersion # Windows Server 1803
#endregion

#region setup edb pull server
configuration PullServerEDB {
    Import-DscResource -ModuleName PSDesiredStateConfiguration -ModuleVersion 1.1
    Import-DscResource -ModuleName xPSDesiredStateConfiguration -ModuleVersion 8.4.0.0

    WindowsFeature dscservice {
        Name   = 'Dsc-Service'
        Ensure = 'Present'
    }

    File PullServerFiles {
        DestinationPath = 'c:\pullserver'
        Ensure = 'Present'
        Type = 'Directory'
        Force = $true
    }

    xDscWebService PSDSCPullServer {
        Ensure                       = 'Present'
        EndpointName                 = 'PSDSCPullServer'
        Port                         = 8080
        PhysicalPath                 = "$env:SystemDrive\inetpub\PSDSCPullServer"
        CertificateThumbPrint        = 'AllowUnencryptedTraffic'
        ModulePath                   = "c:\pullserver\Modules"
        ConfigurationPath            = "c:\pullserver\Configuration"
        DatabasePath                 = "c:\pullserver" 
        State                        = 'Started'
        RegistrationKeyPath          = "c:\pullserver"
        UseSecurityBestPractices     = $false
        DependsOn                    = '[File]PullServerFiles', '[WindowsFeature]dscservice'
    }

    File RegistrationKeyFile {
        Ensure          = 'Present'
        Type            = 'File'
        DestinationPath = "c:\pullserver\RegistrationKeys.txt"
        Contents        = 'cb30127b-4b66-4f83-b207-c4801fb05087'
        DependsOn       = '[File]PullServerFiles'
    }
}

PullServerEDB
Start-DscConfiguration .\PullServerEDB -Wait -Verbose

Get-WindowsFeature -Name Dsc-Service
Get-Website

([xml](Get-Content -Path C:\inetpub\PSDSCPullServer\web.config)).configuration.appsettings.GetEnumerator()
#endregion

#region add configuration for new client
configuration MySuperServer {
    Import-DscResource -ModuleName PSDesiredStateConfiguration -ModuleVersion 1.1

    Node MySuperServer {
        File MySuperFile {
            Ensure = 'Present'
            DestinationPath = 'C:\Windows\Temp\MySuperFile.txt'
            Contents = 'PSConfAsia ROCKS!!!'
        }
    }
}
MySuperServer -OutputPath 'c:\pullserver\Configuration'
New-DscChecksum -Path 'c:\pullserver\Configuration\MySuperServer.mof' -Force

Exit-PSSession
#endregion

#region add pull client
$lcmsession | Enter-PSSession

Get-DscLocalConfigurationManager

cat C:\Windows\System32\drivers\etc\hosts
$edbPullIP = (Resolve-DnsName -Name edbpull.mshome.net -Type A)[0].IPAddress
"$edbPullIP`tpullserver" | Out-File C:\Windows\System32\drivers\etc\hosts -Append -Encoding ascii
Resolve-DnsName -Name pullserver

[dsclocalconfigurationmanager()]
configuration lcm {
    Settings {
        RefreshMode = 'Pull'
    }

    ConfigurationRepositoryWeb SQLPullWeb {
        ServerURL = 'http://pullserver:8080/PSDSCPullServer.svc'
        RegistrationKey = 'cb30127b-4b66-4f83-b207-c4801fb05087'
        AllowUnsecureConnection = $true
        ConfigurationNames = 'MySuperServer'
    }

    ReportServerWeb SQLPullWeb {
        ServerURL = 'http://pullserver:8080/PSDSCPullServer.svc'
        RegistrationKey = 'cb30127b-4b66-4f83-b207-c4801fb05087'
        AllowUnsecureConnection = $true
    }
}
lcm
Set-DscLocalConfigurationManager .\lcm -Verbose

Update-DscConfiguration -Wait -Verbose
cat C:\Windows\Temp\MySuperFile.txt
#endregion

#region get data from pull server.
$uri = 'http://pullserver:8080/PSDSCPullServer.svc{0}'
$irmArgs = @{
    Headers = @{
        Accept = 'application/json'
        ProtocolVersion = '2.0'
    }
    UseBasicParsing = $true
}
# available routes
(Invoke-RestMethod @irmArgs -Uri ($uri -f $null)).value

# Get node object
$agentId = (Get-DscLocalConfigurationManager).AgentId
$node = Invoke-RestMethod @irmArgs -Uri ($uri -f "/Nodes(AgentId = '$agentId')")
$node

# Get node reports
$reports = (Invoke-RestMethod @irmArgs -Uri ($uri -f "/Nodes(AgentId = '$agentId')/Reports")).value
$reports[0]
$reports[0].StatusData | ConvertFrom-Json

Exit-PSSession
#endregion

#region get data from edb
$edbsession | Enter-PSSession

Get-Module -Name DSCPullServerAdmin -ListAvailable
New-DSCPullServerAdminConnection -ESEFilePath C:\pullserver\Devices.edb
Get-DSCPullServerAdminRegistration

# so the file is locked.. this is the main issue with edb, you need to kill the pullserver to get / set / remove data

iisreset /stop

Get-DSCPullServerAdminRegistration
Get-DSCPullServerAdminStatusReport
Exit-PSSession
#endregion