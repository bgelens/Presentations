# Get all DSC resources available on the local system
Get-DscResource

# Get all DSC resources available on the local system from a specific module
Get-DscResource -Module PSDesiredStateConfiguration

# Find DSC resources online; requires packagemanagement module
Find-DscResource

# Find DSC resources in a specific module
Find-DscResource -ModuleName cHyper-V

# Install DSC resource modules from PowerShell Gallery
Find-DscResource -ModuleName xNetworking | Install-Module -Force

# Using custom resources in a configuration
Configuration DemoCustomResourceConfig
{
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    #ModuleVersion is mandatory if there are multiple versions of the module on the local system
    Import-DscResource -ModuleName xNetworking -Name xHostsFile -ModuleVersion 3.2.0.0

    node S16-01
    {
        xHostsFile HostsFileUpdate 
        {
            IPAddress = '109.10.10.10'
            HostName = 'TESTHost'
            Ensure = 'Absent'
        }
    }
}

DemoCustomResourceConfig -OutputPath C:\demoScripts\DemoCustomResourceConfig

# If you are PUSHing this configuration to a remote node, ensure that the custom resource module exists in the Program Files path for the PowerShell modules
# Enact the configuration without copying the module. Understand the error.
Start-DscConfiguration -Path C:\demoScripts\DemoCustomResourceConfig -ComputerName S16-01 -Verbose -Wait

# Copy the module to remote node and try enact again

Copy-Item -Path (Split-Path (Get-Module -Name xNetworking -ListAvailable).ModuleBase) -Recurse -Destination '\\S16-01\C$\Program Files\WindowsPowerShell\Modules'

# you will need -Force since the last enact resulted in error and there is a pending configuration on the remote node.
# Confirm this opening the configuration store on the remote node
Get-DscLocalConfigurationManager -CimSession s16-01
Get-ChildItem -Path '\\S16-01\C$\Windows\System32\Configuration'

# if there is no update to the compiled MOF, you can also use -UseExisting switch
Start-DscConfiguration -Path C:\demoScripts\DemoCustomResourceConfig -ComputerName S16-01 -Verbose -Wait -Force

# or
Start-DscConfiguration -ComputerName S16-01 -Verbose -Wait -UseExisting
