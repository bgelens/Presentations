# Exploring Langauge Extensions
Get-Module -ListAvailable -Name PSDesiredStateConfiguration

# Get all exported commands from PSDesiredStateConfiguration
Get-Command -Module PSDesiredStateConfiguration

# Explore the configuration keyword
Get-Command -Name Configuration | Select CommandType, ModuleName, Parameters

# The ResourceModuleTuplesToImport is a parameter that gets added at runtime; Identifies the modules that are imported in a configuration
Get-Command -Name Configuration | Select -ExpandProperty Parameters

# Other Dynamic keywords from PSDesiredStateConfiguration module
# Load the default CIM Keywords
[Microsoft.PowerShell.DesiredStateConfiguration.Internal.DscClassCache]::LoadDefaultCimKeywords()

# Observe the Node and Import-DscResource keywords in the output. These are used in authoring configurations.
[System.Management.Automation.Language.DynamicKeyword]::GetKeyword() | Select Keyword, ImplementingModule

# Cmdlets that manage configuration
Get-Command -Module PSDesiredStateConfiguration -Noun DSCConfiguration*

# List all resources in the module path
Get-DscResource