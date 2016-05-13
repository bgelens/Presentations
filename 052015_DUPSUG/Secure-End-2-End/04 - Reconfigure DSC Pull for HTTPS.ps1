#region add CA to trusted root
Invoke-WebRequest http://cdp.domain.tld/PSDSC-CA.crt -OutFile $env:TEMP\PSDSC-CA.crt -Verbose
Import-Certificate -FilePath $env:TEMP\PSDSC-CA.crt -CertStoreLocation Cert:\LocalMachine\Root -Verbose
#endregion add CA to trusted root

#region request web server cert
$SecString = 'Pa$sW0rd!' | ConvertTo-SecureString -AsPlainText -Force
$CertReqArgs = @{
    Url = 'https://webenroll.domain.tld/ADPolicyProvider_CEP_UsernamePassword/service.svc/CEP';
    Template = 'Webserver';
    SubjectName = "CN=$env:COMPUTERNAME";
    CertStoreLocation = 'Cert:\LocalMachine\My'
    Credential = New-Object System.Management.Automation.PsCredential('Domain\User', $SecString)
}
$cert = Get-Certificate @CertReqArgs -Verbose
#endregion request web server cert

#region configure pull server with cert
configuration SecureDSCWebPullServer {
    Import-DscResource -ModuleName xPSDesiredStateConfiguration

    WindowsFeature DSCServiceFeature {
        Ensure = 'Present'
        Name = 'DSC-Service'
    }
    xDSCWebService PSDSCPullServer {
        Ensure = 'Present'
        EndpointName = 'PSDSCPullServer'
        Port = 443
        PhysicalPath = "$env:SYSTEMDRIVE\inetpub\wwwroot\PSDSCPullServer"
        CertificateThumbPrint = $cert.Certificate.Thumbprint
        ModulePath = "$env:PROGRAMFILES\WindowsPowerShell\DscService\Modules"
        ConfigurationPath  = "$env:PROGRAMFILES\WindowsPowerShell\DscService\Configuration"
        State = 'Started'
        DependsOn = '[WindowsFeature]DSCServiceFeature'
    }
}
SecureDSCWebPullServer -OutputPath C:\Configs\SecureDSCWebPullServer
Start-DscConfiguration -Path C:\Configs\SecureDSCWebPullServer -Wait -Force -Verbose
#endregion configure pull server with cert