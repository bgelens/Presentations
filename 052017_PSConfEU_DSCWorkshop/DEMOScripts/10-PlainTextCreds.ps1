# Let us see a failed configuration where there are credentials involved
Configuration UserDemo
{
    param (
        [pscredential] $Credential
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Node S12R2-01
    {
        User UserDemo
        {
            UserName = $Credential.UserName
            Password = $Credential
            Description = "local account"
            Ensure = "Present"
            Disabled = $false
            PasswordNeverExpires = $true
            PasswordChangeRequired = $false
        }
    }
}

# Compiling this configuration will fail since storing plain-text passwords in MOF is not allowed.
UserDemo -OutputPath C:\DemoScripts\UserDemo -Credential (Get-Credential)

# We workaround the above restriction by forcing plain-text passwords in MOF. This is done using configuration data
# The PSDscAllowPlainTextPassword in the configuration data specifies that the plaintext passwords in MOF are allowed
$ConfigData = 
@{
    AllNodes = 
    @(
        #Use NodeName = '*' along with PSDscAllowPlainTextPassword if there are multiple nodes in the configuration data
        #@{
        #    NodeName = "*"
        #    PSDscAllowPlainTextPassword = $true
        #},
        @{
            NodeName = "S12R2-01"
            PSDscAllowPlainTextPassword = $true
        }
    )
}

Configuration UserDemo
{
    param (
        [pscredential] $Credential
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Node $AllNodes.NodeName
    {
        User UserDemo
        {
            UserName = $Credential.UserName
            Password = $Credential
            Description = "local account"
            Ensure = "Present"
            Disabled = $false
            PasswordNeverExpires = $true
            PasswordChangeRequired = $false
        }
    }
}

# Compiling this configuration will fail since storing plain-text passwords in MOF is not allowed.
UserDemo -OutputPath C:\DemoScripts\UserDemo -Credential (Get-Credential) -ConfigurationData $ConfigData

#Open the generated MOF and check. You will see the password in plain-text.
psEdit C:\DemoScripts\UserDemo\S12R2-01.mof

#If the credentials used in the configuration are domain user credentials, we will need PSDscAllowDomainUser set to $true in the configuration
$ConfigData = 
@{
    AllNodes = 
    @(
        #Use NodeName = '*' along with PSDscAllowPlainTextPassword if there are multiple nodes in the configuration data
        #@{
        #    NodeName = "*"
        #    PSDscAllowPlainTextPassword = $true
        #},
        @{
            NodeName = "S12R2-01"
            PSDscAllowPlainTextPassword = $true
            PSDscAllowDomainUser = $true
        }
    )
}
