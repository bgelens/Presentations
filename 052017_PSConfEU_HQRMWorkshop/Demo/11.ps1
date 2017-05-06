# completed example
# download from https://gist.github.com/bgelens

<#
    .SYNOPSIS
        Template for creating DSC Resource Unit Tests
    .DESCRIPTION
        To Use:
        1. Copy to \Tests\Unit\ folder and rename <ResourceName>.tests.ps1 (e.g. MSFT_xFirewall.tests.ps1)
        2. Customize TODO sections.
        3. Delete all template comments (TODOs, etc.)

    .NOTES
        There are multiple methods for writing unit tests. This template provides a few examples
        which you are welcome to follow but depending on your resource, you may want to
        design it differently. Read through our TestsGuidelines.md file for an intro on how to
        write unit tests for DSC resources: https://github.com/PowerShell/DscResources/blob/master/TestsGuidelines.md
#>

#region HEADER

# Unit Test Template Version: 1.2.0
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName 'NetworkingDsc' `
    -DSCResourceName 'MSFT_LMHost' `
    -TestType Unit

#endregion HEADER

function Invoke-TestSetup {
}

function Invoke-TestCleanup {
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}

# Begin Testing
try
{
    Invoke-TestSetup

    InModuleScope 'MSFT_LMHost' {

        $MockLMHostEnabled = New-Object -TypeName CimInstance -ArgumentList 'Win32_NetworkAdapterConfiguration' | 
            Add-Member -MemberType NoteProperty -Name WINSEnableLMHostsLookup -Value $true -PassThru

        $MockLMHostDisabled= New-Object -TypeName CimInstance -ArgumentList 'Win32_NetworkAdapterConfiguration' | 
            Add-Member -MemberType NoteProperty -Name WINSEnableLMHostsLookup -Value $false -PassThru

        Describe 'MSFT_LMHost\Get-TargetResource' {
            It 'Returns a hashtable' {                
                $targetResource = Get-TargetResource -IsSingleInstance 'Yes' -Enable $true
                $targetResource -is [System.Collections.Hashtable] | Should Be $true
            }
        }

        Describe 'MSFT_LMHost\Set-TargetResource' {
            Context 'Succesfull change' {
                Mock -CommandName Invoke-CimMethod -MockWith {return @{ReturnValue=0}}
                It 'Should not throw' {
                    { Set-TargetResource -IsSingleInstance 'Yes' -Enable $true } | Should Not Throw
                }
            }

            Context 'Unsuccessfull change' {
                Mock -CommandName Invoke-CimMethod -MockWith {return @{ReturnValue=91}}
                It 'Should throw' {
                    { Set-TargetResource -IsSingleInstance 'Yes' -Enable $true } | Should Throw
                }
            }
        }

        Describe 'MSFT_LMHost\Test-TargetResource' {
            Context 'Invoking with LMHost currently enabled' {
                Mock -CommandName Test-LMHostEnabled -MockWith {return $true}
                It 'Should return "true" when Enable is set to "true" and current state is "true"' {
                    Test-TargetResource -IsSingleInstance 'Yes' -Enable $true | Should Be $true
                }
                It 'Should return "false" when Enable is set to "false" and current state is "true"' {
                    Test-TargetResource -IsSingleInstance 'Yes' -Enable $false | Should Be $false
                }
            }

            Context 'Invoking with LMHost currently disabled' {
                Mock -CommandName Test-LMHostEnabled -MockWith {return $false}
                It 'Should return "true" when Enable is set to "false" and current state is "false"' {
                    Test-TargetResource -IsSingleInstance 'Yes' -Enable $false | Should Be $true
                }
                It 'Should return "false" when Enable is set to "true" and current state is "false"' {
                    Test-TargetResource -IsSingleInstance 'Yes' -Enable $true | Should Be $false
                }
            }
        }

        Describe 'MSFT_LMHost\Test-LMHostEnabled ' {
            Context 'Invoking with LMHost currently enabled' {
                Mock -CommandName Get-CimInstance -MockWith {return $MockLMHostEnabled}
                It 'Should return "true" when WINSEnableLMHostsLookup property is "true"' {
                    Test-LMHostEnabled | Should Be $true
                }
            }

            Context 'Invoking with LMHost currently disabled' {
                Mock -CommandName Get-CimInstance -MockWith {return $MockLMHostDisabled}
                It 'Should return "false" when WINSEnableLMHostsLookup property is "false"' {
                    Test-LMHostEnabled | Should Be $false
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
