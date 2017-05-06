# If you observe the configuration command types, one of the available parameters is -ConfigurationData
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

Get-Command -Name ArchiveDemo | Select -ExpandProperty Parameters

# Configuration Data in DSC can be used to separate structural configuration from environmental configuration
# Here is a sample structure
$ConfigData = 
@{
    AllNodes = 
    @(
        @{
            NodeName = "VM-1"
            Role     = "WebServer"
        },
        @{
            NodeName = "VM-2"
            Role     = "SQLServer"
        },
        @{
            NodeName = "VM-3"
            Role     = "WebServer"
        }
    )

    NonNodeData = @{

    }
}

# Let us convert our configuration to use configurationdata
# When nodename is *, all properties and arguments within that hash will be available to all 
$ConfigData = 
@{
    AllNodes = 
    @(
        @{
            NodeName    = "S16-01"
            ArchivePath = "C:\Demoscripts\WebScripts.zip"
        },
        @{
            NodeName    = "S12R2-01"
            ArchivePath = "C:\Demoscripts\AppScripts.zip"
        },
        @{
            NodeName = "*"
            DestinationPath = "C:\Scripts"
        }
    ) 
}

# Observe how the configuration changes
Configuration ArchiveDemo {
    Import-DscResource –ModuleName 'PSDesiredStateConfiguration'
    Node $AllNodes.NodeName {
        Archive ArchiveDemo {
            Path = $Node.ArchivePath
            Destination = $Node.DestinationPath
            Ensure="Present"
        }
    }
}

# Use -ConfigurationData to pass the Configuration Data 
ArchiveDemo -OutputPath C:\Demoscripts\Archivedemo -ConfigurationData $ConfigData

# Enact configuration
Start-DscConfiguration -Path C:\Demoscripts\Archivedemo -Wait -Verbose -ComputerName S16-01,S12R2-01

# Configuration data can also be used for conditional resource instance inclusion
# For example, in the below config, we conifgure hostsfile resource only if the role of the node is a web server
$ConfigData = 
@{
    AllNodes = 
    @(
        @{
            NodeName    = "S16-01"
            ArchivePath = "C:\Demoscripts\WebScripts.zip"
            Role = 'Web'
        },
        @{
            NodeName    = "S12R2-01"
            ArchivePath = "C:\Demoscripts\AppScripts.zip"
            Role = 'App'
        },
        @{
            NodeName = "*"
            DestinationPath = "C:\Scripts"
        }
    ) 
}

# Observe how the configuration changes
Configuration ArchiveDemo {
    Import-DscResource –ModuleName 'PSDesiredStateConfiguration'
    Import-DscResource –ModuleName xNetworking -ModuleVersion 3.2.0.0

    Node $AllNodes.Where{$_.Role -eq "Web"}.NodeName
    {
        xHostsFile AddHostsFile {
            IPAddress = '109.101.0.10'
            HostName = 'TESTHost1'
            Ensure = "Present"
        }
    }

    Node $AllNodes.NodeName {
        Archive ArchiveDemo {
            Path = $Node.ArchivePath
            Destination = $Node.DestinationPath
            Ensure="Present"
        }
    }
}

# Use -ConfigurationData to pass the Configuration Data 
ArchiveDemo -OutputPath C:\Demoscripts\Archivedemo -ConfigurationData $ConfigData

# Open the generated MOF and verify that the HostsFile resource is added only to S16-01
psEdit C:\Demoscripts\Archivedemo\S16-01.MOF
psEdit C:\Demoscripts\Archivedemo\S12R2-01.MOF

# Enact configuration
Start-DscConfiguration -Path C:\Demoscripts\Archivedemo -Wait -Verbose -ComputerName S16-01,S12R2-01
