# we verified in the LCMBasics demo that all the configuration runas Local System account
# But, Some resource configuration requires running as a specific user.

Configuration RunAsDemo
{
    Import-DscResource -moduleName PSDesiredStateConfiguration
    
    Node S12R2-01
    {
        #This creates a group if it does not exist and adds the members
        Script AccessShare {
            GetScript = {
                return @{}
            }
            TestScript = {
                Write-Verbose -Message "This configuration is running as: $(whoami)"
                if (dir \\s16-01\c$) {
                    $true
                } else {
                    $false
                }
            }
            SetScript = {
                $null
            }
        }
    }
}

RunAsDemo -OutputPath C:\DemoScripts\RunAsDemo

# This enact will fail since LCM runs as SYSTEM and cannot access other server C$ share
Start-DscConfiguration -Path C:\DemoScripts\RunAsDemo -Verbose -Wait -Force

# Using PsDscRunAsCredential, the LCM can be made aware of custom credential for resource execution instead of SYSTEM account
$ConfigData = 
@{
    AllNodes = 
    @(
        @{
            NodeName = "S12R2-01"
            PSDscAllowPlainTextPassword = $true
            PSDscAllowDomainUser = $true
        }
    )
}

Configuration RunAsDemo 
{
    Node S12R2-01
    {
        #This creates a group if it does not exist and adds the members
        Script AccessShare {
            GetScript = {
                return @{}
            }
            TestScript = {
                Write-Verbose -Message "This configuration is running as: $(whoami)"
                if (dir \\s16-01\c$) {
                    $true
                } else {
                    $false
                }
            }
            SetScript = {
                $null
            }
            PsDscRunAsCredential = Get-Credential
        }
    }
}

RunAsDemo -outputPath C:\DemoScripts\RunAsDemo -ConfigurationData $ConfigData
Start-DscConfiguration -Path C:\DemoScripts\RunAsDemo -ComputerName S12R2-01 -Verbose -Wait -Force
