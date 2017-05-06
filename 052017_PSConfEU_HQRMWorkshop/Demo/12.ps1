# Templates
Start-Process microsoft-edge:https://github.com/PowerShell/DscResources/blob/master/Tests.Template

# Add integration test
wget -Uri https://raw.githubusercontent.com/PowerShell/DscResources/master/Tests.Template/integration_template.ps1 -OutFile .\NetworkingDsc\Tests\Integration\MSFT_LMHost.Integration.Tests.ps1
wget -Uri https://raw.githubusercontent.com/PowerShell/DscResources/master/Tests.Template/integration_config_template.ps1 -OutFile .\NetworkingDsc\Tests\Integration\MSFT_LMHost.Config.ps1

psedit .\NetworkingDsc\Tests\Integration\MSFT_LMHost.Integration.Tests.ps1
psedit .\NetworkingDsc\Tests\Integration\MSFT_LMHost.Config.ps1

# add test
It 'Should be in Desired State' {
    Test-DscConfiguration -Verbose | Should Be $true
}

# add config
configuration MSFT_LMHost_config {
    Import-DscResource -ModuleName 'NetworkingDsc'
    node localhost {
        LMHost Integration_Test {
            IsSingleInstance = 'Yes'
            Enable = $false
        }
    }
}