# LCM is implemented as a set of CIM providers
Get-CimClass -Namespace root/microsoft/windows/desiredstateconfiguration -ClassName MSFT_*

# MSFT_DSCLocalConfigurationManager implements core LCM
# Implements several methods that the commands from PSDesiredStateConfiguration module invoke
Get-CimClass -ClassName MSFT_DSCLocalConfigurationManager -Namespace root/microsoft/windows/desiredstateconfiguration | Select -ExpandProperty CimClassMethods

# MSFT_DSCMetaConfiguration implements the LCM configuration settings
Get-CimClass -ClassName MSFT_DSCMetaConfiguration -Namespace root/microsoft/windows/desiredstateconfiguration | Select -ExpandProperty CimClassProperties

# The Get-DscLocalConfigurationManager command retrieves the LCM settings
# Understand the configurable settings
Get-DscLocalConfigurationManager

# LCM itself can be configured using a meta configuration document; These meta resources are exported by PSDesiredStateConfigurationEngine Module
# The PSDesiredStateConfigurationEngine is v2; These resources won't get listed in the output of Get-DscResource 
[Microsoft.PowerShell.DesiredStateConfiguration.Internal.DscClassCache]::LoadDefaultCimKeywords()
[System.Management.Automation.Language.DynamicKeyword]::GetKeyword() | Where-Object { $_.ImplementingModule -eq 'PSDesiredStateConfigurationEngine' } | Select Keyword

# Get the configurale properties on a meta resource
[System.Management.Automation.Language.DynamicKeyword]::GetKeyword('Settings') | Select -ExpandProperty Properties

# The v1 meta resource for configuring LCM is LocalConfigutationManager
[System.Management.Automation.Language.DynamicKeyword]::GetKeyword('LocalConfigurationManager')
[System.Management.Automation.Language.DynamicKeyword]::GetKeyword('LocalConfigurationManager').Properties

# LCM runs as SYSTEM account. Therefore, has access to all administrator level changes on the local system. 
# There are certain scenarios where this is a problem and will discuss that when talking about DSC RunAs Crednetials
# This can be verified using a DSC configuration document or by using Invoke-DscResource. 
# Don't worry about whats in this document but pay attention to the verbose output.

# if you don't want to apply, you can make use of Invoke-DscResource to test stuff out
Invoke-DscResource -ModuleName PSDesiredStateConfiguration -Name Script -Method Test -Verbose -Property @{
    GetScript = {
        return @{
            GetScript = $GetScript
            SetScript = $SetScript
            TestScript = $TestScript
            Result = whoami.exe
        }
    }
    SetScript = {
        $null
    }
    TestScript = {
        Write-Verbose -Message "This configuration is running as: $(whoami)"
        return $true
    }
}


# The following is a DSC configuration document that uses script resource
Configuration SYSTEMDemo
{
    Script Demo
    {
        GetScript = {
            return @{}
        }

        SetScript = {
            Write-Verbose -Message "This configuration is running as: $(whoami)"
        }

        TestScript = {
            return $false
        }
    }
}

SYSTEMDemo -outputPath C:\DemoScripts\SystemDemo
Start-DscConfiguration -Path C:\DemoScripts\SystemDemo -Verbose -Wait
