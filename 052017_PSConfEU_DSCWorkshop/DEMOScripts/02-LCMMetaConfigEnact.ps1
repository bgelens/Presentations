# Example meta configuration document - v2
# Understand the structure
# Understand how to use intellisense
[DSCLocalConfigurationManager()]
configuration LCMConfig
{
    Node localhost
    {
        Settings
        {
            RefreshMode = 'Push'
        }
    }
}

# Running the meta configuration compiles it into a MOF
LCMConfig

# Set-DscLocalConfigurationManager configures the LCM from the compiled MOF
Set-DscLocalConfigurationManager -Path .\LCMConfig