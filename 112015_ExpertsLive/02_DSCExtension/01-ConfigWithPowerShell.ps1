$DSCExtensionPath = $DTE.ActiveDocument.Path

#region Create configuration.ps1
{
Configuration WebSite { 
    Import-DscResource -Module PSDesiredStateConfiguration
    Import-DscResource -Module xWebAdministration

    WindowsFeature IIS {
        Ensure          = 'Present'
        Name            = 'Web-Server'
    }

    WindowsFeature AspNet45 {
        Ensure          = 'Present'
        Name            = 'Web-Asp-Net45'
    }

    xWebsite DefaultSite {
        Ensure          = 'Present'
        Name            = 'Default Web Site'
        State           = 'Stopped'
        PhysicalPath    = 'C:\inetpub\wwwroot'
        DependsOn       = '[WindowsFeature]IIS'
    }

    Archive WebContent {
        Ensure          = 'Present'
        Path            = "$PSScriptRoot\BakeryWebsite.zip"
        Destination     = 'C:\inetpub'
        Force           = $true
        DependsOn       = '[WindowsFeature]IIS'
    }

    xWebsite BakeryWebSite {
        Ensure          = 'Present'
        Name            = 'BakeryWebsite'
        State           = 'Started'
        PhysicalPath    = 'C:\inetpub\BakeryWebsite'
        DependsOn       = '[Archive]WebContent'
    }
}
}.Ast.EndBlock.Extent.Text | Out-File "$DSCExtensionPath\BakeryWebsite.ps1" -Force -Encoding ascii
#endregion Create configuration.ps1

#region set variables
$RG = Get-AzureRmResourceGroup -Name EL201501
$VM = $RG | Get-AzureRmVM
$FQDN = ($RG | Get-AzureRmPublicIpAddress).DnsSettings.Fqdn
$storage = $RG | Get-AzureRmStorageAccount
#endregion set variables

start microsoft-edge:http://$fqdn

#region create archive
$ArchiveParams = @{
    ConfigurationPath = "$DSCExtensionPath\BakeryWebsite.ps1"
    AdditionalPath = "$DSCExtensionPath\BakeryWebsite.zip"
    OutputArchivePath = "$DSCExtensionPath\BakeryWebsite.ps1.zip"
    Force = $true
}

Publish-AzureRmVMDscConfiguration @ArchiveParams
explorer $DSCExtensionPath

$ArchiveParams.Remove('OutputArchivePath')
$storage | Publish-AzureRmVMDscConfiguration @ArchiveParams
#endregion create archive

#region Enable DSC extension
$Props = @{
    ResourceGroupName         = $RG.ResourceGroupName
    VMName                    = $VM.Name
    ArchiveStorageAccountName = $storage.StorageAccountName
    ArchiveBlobName           = 'BakeryWebsite.ps1.zip'
    ConfigurationName         = 'WebSite'
    Version                   = '2.8'
    Location                  = $RG.Location
    WmfVersion                = '4.0'
}

$AADSCExtStatus = Set-AzureRmVMDscExtension @Props
#endregion Enable DSC extension

start microsoft-edge:http://$fqdn