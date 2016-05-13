<#
    PackageManagement
           ||
        Providers
           ||
         Sources
#>

#region Explore PackageManagement Module
Get-Module -Name PackageManagement -ListAvailable
Get-Command -Module PackageManagement
#endregion

#region Package Provider/Source
Get-PackageProvider #list providers currently loaded for PackageManagement

Find-PackageProvider #finds providers registered with PowerShellGet

#Install-PackageProvider

Get-PackageSource #-ForceBootstrap if provider is not installed, it will be installed
#Register-PackageSource

#endregion

#region Explore PowerShellGet Module (Provider)
Get-Module -Name PowerShellGet -ListAvailable
Get-Command -Module PowerShellGet
#endregion

#region find and install a module on PSGallery
#PowerShellGet cmdlets
Find-Module |Where-Object -FilterScript {$_.author -like '*Gelens*'} 
Save-Module -Name cWindowsContainer -Path c:\ -Verbose
Install-Module -Name cWindowsContainer
Uninstall-Module -Name cWindowsContainer

#PackageManagement cmdlets
Find-Package -Source PSGallery -Name cWindowsContainer
Save-Package -Name cWindowsContainer -Source PSGallery -Path c:\
Install-Package -Name cWindowsContainer -Source PSGallery
Uninstall-Package -Name cWindowsContainer
#endregion

#region add packageprovider and install package from there
Find-PackageProvider chocolatey
Install-PackageProvider -Name chocolatey -Force -ForceBootstrap
#Open new PS session
Get-PackageSource
Find-Package -Source chocolatey -Name zoomit | Install-Package
Get-ChildItem -Path C:\Chocolatey\lib\zoomit.*\tools\ -Recurse
#endregion

#region add packagesource
Start-Process microsoft-edge:http://10.10.10.2:8080
#powershellget cmdlets
Register-PSRepository -SourceLocation 'http://10.10.10.2:8080/api/v2' `
                      -PublishLocation 'http://10.10.10.2:8080/api/v2/package' `
                      -Name CDCGallery
Get-PSRepository
#packagemanagement cmdlets
Register-PackageSource -Name CDCGallery `
                       -PublishLocation 'http://10.10.10.2:8080/api/v2/package' `
                       -Location 'http://10.10.10.2:8080/api/v2' `
                       -ProviderName PowerShellGet

Get-PackageSource -ProviderName PowerShellGet

Find-Module -Repository CDCGallery
#endregion

#region NanoServer Packagemanagement
$PassWord = (ConvertTo-SecureString -String 'P@ssw0rd!' -AsPlainText -Force)
$SessionArgs = @{
    ComputerName = '10.10.10.20'
    Credential = [pscredential]::new('Administrator',$PassWord)
}
$PackageSession = New-PSSession @SessionArgs

$PackageSession | Enter-PSSession
Find-PackageProvider -Name NanoServerPackage | Install-PackageProvider -ForceBootstrap -Force -Verbose
Exit-PSSession
$PackageSession | Enter-PSSession #new session
Get-Package -ProviderName NanoServerPackage
Find-Package -Name Microsoft-NanoServer-Defender-Package -ProviderName NanoServerPackage
Install-Package -Name Microsoft-NanoServer-Defender-Package -ProviderName NanoServerPackage
Get-Package -ProviderName NanoServerPackage
Get-WindowsOptionalFeature -Online

Get-Command -Module NanoServerPackage
Find-NanoServerPackage -Name *wim*
Exit-PSSession
#endregion