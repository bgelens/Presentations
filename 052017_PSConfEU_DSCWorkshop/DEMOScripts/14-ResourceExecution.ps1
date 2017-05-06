# DSC resource module execution follows a standard process
# This can be seen in the Verbose output during configuration enact process using Start-DscConfiguration
# Another way to visualize that is using the script resource
Configuration ResourceDemo 
{
    Script Demo
    {
        GetScript = {
            return @{}
        }

        SetScript = {
            Write-Verbose -Message 'Set if executing since Test returned false'
        }

        TestScript = {
            Write-Verbose -Message 'Returning False from test method'
            return $false
        }
    }
}

ResourceDemo -outputPath C:\DemoScripts\ResourceDemo
Start-DscConfiguration -Path C:\DemoScripts\ResourceDemo -Verbose -Wait

# We can see the Set skipped when Test returns True
Configuration ResourceDemo 
{
    Script Demo
    {
        GetScript = {
            return @{}
        }

        SetScript = {
            Write-Verbose -Message 'Set if executing since Test returned false'
        }

        TestScript = {
            Write-Verbose -Message 'Returning True from test method'
            return $true
        }
    }
}

ResourceDemo -outputPath C:\DemoScripts\ResourceDemo
Start-DscConfiguration -Path C:\DemoScripts\ResourceDemo -Verbose -Wait
