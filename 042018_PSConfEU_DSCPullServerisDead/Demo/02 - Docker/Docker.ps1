Install-WindowsFeature dsc-service
Start-Process msiexec -ArgumentList '/i sqlncli.msi /qn IACCEPTSQLNCLILICENSETERMS=YES' -Wait
New-Item -ItemType SymbolicLink -Path C:\Windows\System32\WindowsPowerShell\v1.0\modules\PSDesiredStateConfiguration\PullServer\en -Value C:\Windows\System32\WindowsPowerShell\v1.0\modules\PSDesiredStateConfiguration\PullServer\en-us
Copy-Item C:\Windows\System32\WindowsPowerShell\v1.0\modules\PSDesiredStateConfiguration\PullServer\Microsoft.Powershell.DesiredStateConfiguration.Service.dll C:\Windows\System32\WindowsPowerShell\v1.0\modules\PSDesiredStateConfiguration\PullServer\en\Microsoft.Powershell.DesiredStateConfiguration.Service.Resources.dll
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
