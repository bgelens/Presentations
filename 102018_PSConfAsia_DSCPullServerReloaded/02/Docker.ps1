Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters' -Name ServerPriorityTimeLimit -Value 0 -Type DWord
Install-WindowsFeature dsc-service
Invoke-DscResource -ModuleName xPSDesiredStateConfiguration -Name xDscWebService -Method Set -Property @{
    Ensure = 'Present'
    EndpointName = 'PSDSCPullServer'
    Port = 8080
    PhysicalPath = "$env:SystemDrive\inetpub\PSDSCPullServer"
    CertificateThumbPrint='AllowUnencryptedTraffic'
    ModulePath="$env:PROGRAMFILES\WindowsPowerShell\DscService\Modules"
    ConfigurationPath="$env:PROGRAMFILES\WindowsPowerShell\DscService\Configuration"
    State='Started'
    RegistrationKeyPath="$env:PROGRAMFILES\WindowsPowerShell\DscService"
    AcceptSelfSignedCertificates=$true
    UseSecurityBestPractices=$false
    SqlProvider=$true
    SqlConnectionString='#CONNECTIONSTRING#'
}
Remove-Website -Name 'Default Web Site'
Stop-Website -Name PSDSCPullServer
