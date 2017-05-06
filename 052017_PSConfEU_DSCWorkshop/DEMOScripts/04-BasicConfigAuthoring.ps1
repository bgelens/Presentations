Configuration ArchiveDemo {
    Node localhost {
        Archive ArchiveDemo {
            Path = "C:\demoscripts\Scripts.zip"
            Destination = "C:\Scripts"
            Ensure="Present"
        }
    }
}

# Compile the configuration to a MOF
# Without -OutputPath, a folder with configuration name gets created in the current working directory
# When compiling you will see a warning message about importing PSDesiredStateConfiguration module
ArchiveDemo -OutputPath C:\DemoScripts\Archivedemo

# Open the compiled MOF and understand the contents
psEdit C:\DemoScripts\Archivedemo\localhost.mof

# using node keyword is not mandatory
# The following configuration will also compile into localhost.mof
Configuration ArchiveDemo {
    Import-DscResource –ModuleName 'PSDesiredStateConfiguration'
    Archive ArchiveDemo {
        Path = "C:\demoscripts\Scripts.zip"
        Destination = "C:\Scripts"
        Ensure="Present"
    }
}
ArchiveDemo -OutputPath C:\DemoScripts\Archivedemo
psEdit C:\DemoScripts\Archivedemo\localhost.mof


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

ArchiveDemo -OutputPath C:\DemoScripts\Archivedemo
psEdit C:\DemoScripts\Archivedemo\S16-01.mof
Get-ChildItem C:\DemoScripts\Archivedemo
