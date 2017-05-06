# CB-01
# Do I have a resource inbox?
Get-DscResource

# DSC ResourceKit maybe?
$Result = Find-Module -Tag DSCResourceKit -Name *RemoteDesktop*
$Result
Start-Process -FilePath iexplore -ArgumentList $($Result[1].ProjectUri)

# install and investigate
$Result[1] | Install-Module -Force

Get-DscResource -Module xRemoteDesktopSessionHost

# explore xRDSessionDeployment
Get-DscResource -Name xRDSessionDeployment -Syntax

# WebAccess Server and SessionHost mandatory... We don't deploy WebAccess servers..
# adjust or?

$GitHubArgs = @{
    FilePath = 'iexplore.exe'
    ArgumentList = 'https://github.com/Azure/azure-quickstart-templates/tree/master/rds-deployment'
}
Start-Process @GitHubArgs

$DownloadArgs = @{
    Uri = 'https://github.com/Azure/azure-quickstart-templates/raw/master/rds-deployment/Configuration.zip'
    OutFile = "$pwd\Configuration.zip"
}
Invoke-WebRequest @DownloadArgs

Unblock-File -Path "$pwd\Configuration.zip"
Expand-Archive -Path "$pwd\Configuration.zip" -DestinationPath "$pwd\Configuration"
Get-ChildItem  -Path "$pwd\Configuration\xRemoteDesktopSessionHost\DSCResources"

# install module
$version = (Test-ModuleManifest -Path "$pwd\Configuration\xRemoteDesktopSessionHost\xRemoteDesktopSessionHost.psd1").Version
Copy-Item -Path "$pwd\Configuration\xRemoteDesktopSessionHost" -Recurse -Destination "C:\Program Files\WindowsPowerShell\Modules\xRemoteDesktopSessionHost\$version" -Force

Get-DscResource -Name xRDSessionDeployment -Syntax -Module @{
    ModuleName = 'xRemoteDesktopSessionHost'
    RequiredVersion = $version.ToString()
}

# now WebAccess server is not mandatory and more resources!
# will use this module as the basis and remove "newer" but less usefull one
Get-Module -FullyQualifiedName @{ModuleName = 'xRemoteDesktopSessionHost';RequiredVersion = $Result[1].Version} -ListAvailable |
    Uninstall-Module -Force

Get-Module -Name 'xRemoteDesktopSessionHost' -ListAvailable

# copy module to all nodes
'sh-01','sh-02' | ForEach-Object -Process {
    $pssession = New-PSSession -ComputerName $_
    $CopyArgs = @{
        Recurse = $true
        ToSession = $pssession
        Path = 'C:\Program Files\WindowsPowerShell\Modules\xRemoteDesktopSessionHost'
        Destination = 'C:\Program Files\WindowsPowerShell\Modules'
        Force = $true
    }
    Copy-Item @CopyArgs
    $pssession | Remove-PSSession
}