# The earlier configurations had the property arguments and node names hard coded.
# Configurations are similar to PowerShell functions
# they can be parameterized
Configuration ArchiveDemo {
    param (
        [String[]] $NodeNames = 'localhost',
        [String] $ArchivePath,
        [String] $DestinationPath
    )

    Import-DscResource –ModuleName 'PSDesiredStateConfiguration'
    Node $NodeNames {
        Archive ArchiveDemo {
            Path = $ArchivePath
            Destination = $DestinationPath
            Ensure="Present"
        }
    }
}

# Compile configuration
# Observe that the parameter names from the configuration are available as paramters in the configuration command
ArchiveDemo -OutputPath C:\Demoscripts\Archivedemo -NodeNames 'S16-01','S12R2-01' -ArchivePath C:\Demoscripts\Scripts.zip -DestinationPath C:\Scripts

# enact configuration
Start-DscConfiguration -Path C:\DemoScripts\Archivedemo -ComputerName 'S16-01','S12R2-01' -Verbose -Wait -Force
