# The following configuration will compile into localhost.mof
Configuration ArchiveDemo {
    Import-DscResource –ModuleName 'PSDesiredStateConfiguration'
    Archive ArchiveDemo {
        Path = "C:\demoscripts\Scripts.zip"
        Destination = "C:\Scripts"
        Ensure="Present"
    }
}

# Compile config
ArchiveDemo -OutputPath C:\DemoScripts\Archivedemo

# Specifying remote node names
Configuration ArchiveDemo {
    Import-DscResource –ModuleName 'PSDesiredStateConfiguration'
    Node @('S16-01','S12R2-01') {
        Archive ArchiveDemo {
            Path = "C:\demoscripts\Scripts.zip"
            Destination = "C:\Scripts"
            Ensure="Present"
        }
    }
}

# compile config for remote nodes
ArchiveDemo -OutputPath C:\DemoScripts\Archivedemo

# Get current configuration before applying this
Get-DscConfiguration

# Enact configuration; enacts on the local system
# Without -Wait, this cmdlet creates a background job
# -Verbose is the best way to learn what is happening during resource configuration; provided the resource module implemented verbose output :D
# Start-DscConfiguration is about PUSH method
# Start-DscConfiguration looks at the -Path argument and finds all MOF files. The basename of the MOF is the computername
# A Cimsession is created with that computer and the configuration get sent to the remote node as byte array over WSMAN
Start-DscConfiguration -Path C:\DemoScripts\ArchiveDemo -Verbose -Wait

# get current configuration again
Get-DscConfiguration

# Enact only a single node
# You can select the right MOF instead of applying configuration on all remote nodes using -ComputerName
Start-DscConfiguration -Path C:\DemoScripts\ArchiveDemo -Verbose -Wait -ComputerName S16-01

# Get Dsc Current state from remote nodes
Get-DscConfiguration -CimSession S16-01, S12R2-01

# Another method of configuration enact (can be PUSH) is to publish and then enact
# This copies the MOF as pending.mof to the remote node configuration store
Publish-DscConfiguration -Path C:\DemoScripts\Archivedemo -ComputerName S16-01 -Verbose
# you can see that the LCM knows about a pending configuration
Get-DscLocalConfigurationManager -CimSession S16-01

# enact configuration by using Start-DscConfiguration -UseExistsing
Start-DscConfiguration -ComputerName S16-01 -UseExisting -wait -Verbose
