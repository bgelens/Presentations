# Composite resource module are created out of parameterized configurations
$configScript = @'
Configuration ExtractResource {
    param (
        [Parameter(Mandatory)]
        [String] $ArchivePath,
        [Parameter(Mandatory)]
        [String] $DestinationPath
    )

    Import-DscResource –ModuleName "PSDesiredStateConfiguration"
    Archive ArchiveDemo {
        Path = $ArchivePath
        Destination = $DestinationPath
        Ensure="Present"
    }
}
'@

# Create the folder structure needed for this composite resource
mkdir C:\DemoScripts\MyCompositeResourceModule\DSCResources\ExtractResource -Force

# Take a look at the structure of the above folder
tree /f /A C:\DemoScripts\MyCompositeResourceModule

# Save the configuration script text as ExtractResource.schema.psm1 file
$configScript | Out-File -FilePath C:\DemoScripts\MyCompositeResourceModule\DSCResources\ExtractResource\ExtractResource.schema.psm1 -Force

# generate a manifest file for this resource
New-ModuleManifest -Path C:\DemoScripts\MyCompositeResourceModule\DSCResources\ExtractResource\ExtractResource.psd1 -rootModule 'ExtractResource.schema.psm1'

# generate a manifest for the module
New-ModuleManifest -Path C:\DemoScripts\MyCompositeResourceModule\MyCompositeResourceModule.psd1 -DscResourcesToExport 'ExtractResource'

# Check the folder structure
tree /f /A C:\DemoScripts\MyCompositeResourceModule

# Copy the module folder to C:\Program Files, or user profile because?
Copy-Item -Path C:\DemoScripts\MyCompositeResourceModule -Destination 'C:\Program Files\WindowsPowerShell\Modules' -Container -Recurse -Force

# Verify that the resource appears in Get-DscResource
Get-DscResource -Module MyCompositeResourceModule

# Verify the syntax for this resource
Get-DscResource -Module MyCompositeResourceModule -Syntax

# Use the resource in a configuration
Configuration CompositeDemo 
{
    Import-DscResource -ModuleName MyCompositeResourceModule -Name ExtractResource

    ExtractResource ExtractDemo
    {
        ArchivePath = 'C:\DemoScripts\Scripts.zip'
        DestinationPath = 'C:\Scripts'   
    }
}

CompositeDemo -outputPath C:\Demoscripts\CompositeDemo
psEdit C:\demoscripts\CompositeDemo\localhost.mof

Start-DscConfiguration -Path C:\Demoscripts\CompositeDemo -Verbose -Wait -force
