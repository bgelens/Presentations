# Get Dsc Current state from remote nodes
Get-DscConfiguration -CimSession S16-01, S12R2-01

# Get Dsc Configuration status
Get-DscConfigurationStatus -CimSession S16-01

# Use -All switch to see all configuration enacts happend on the remote node
Get-DscConfigurationStatus -CimSession S16-01 -All

# Test DesiredState on the remote nodes
# True means that the system is in desired state
Test-DscConfiguration -ComputerName S16-01

# Get detailed report
Test-DscConfiguration -ComputerName S16-01 -Detailed

# Induce failure
# Delete the C:\Scripts folder on remote node and test again
Remove-Item '\\S16-01\C$\Scripts' -Recurse -Force
Test-DscConfiguration -ComputerName S16-01 -Detailed

# test the desired state of a system against a reference configuration
Test-DscConfiguration -ComputerName S16-01 -ReferenceConfiguration C:\DemoScripts\Archivedemo\S16-01.mof -Verbose

