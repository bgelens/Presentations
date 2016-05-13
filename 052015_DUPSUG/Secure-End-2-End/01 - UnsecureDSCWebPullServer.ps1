configuration UnsecureDSCWebPullServer {
    Import-DscResource -ModuleName xPSDesiredStateConfiguration

    WindowsFeature DSCServiceFeature {
        Ensure = 'Present'
        Name = 'DSC-Service'
    }
    xDSCWebService PSDSCPullServer {
        Ensure = 'Present'
        EndpointName = 'PSDSCPullServer'
        Port = 8080
        PhysicalPath = "$env:SYSTEMDRIVE\inetpub\wwwroot\PSDSCPullServer"
        CertificateThumbPrint = 'AllowUnencryptedTraffic'
        ModulePath = "$env:PROGRAMFILES\WindowsPowerShell\DscService\Modules"
        ConfigurationPath  = "$env:PROGRAMFILES\WindowsPowerShell\DscService\Configuration"
        State = 'Started'
        DependsOn = '[WindowsFeature]DSCServiceFeature'
    }
}
UnsecureDSCWebPullServer -OutputPath C:\Configs\UnsecureDSCWebPullServer
Start-DscConfiguration -Path C:\Configs\UnsecureDSCWebPullServer -Wait -Force -Verbose