Set-StrictMode -Version latest
$ErrorActionPreference = 'Stop'
$Module = (Resolve-Path $PSScriptRoot\DscResources\EL_DockerD\*.psm1).Path

Import-Module -Name $Module -Force -verbose

#region Pester Tests
InModuleScope 'EL_DockerD'{
    
    #Common Args
    $ResArgs = @{
        Ensure = 'Present'
        Path = 'C:\Program Files\Docker'
    }

    #region Function Get-TargetResource
    Describe "Get-TargetResource" {
        It 'Returns a hashtable' {                
            $targetResource = Get-TargetResource @ResArgs
            $targetResource -is [System.Collections.Hashtable] | Should Be $true
        }

        It 'Returns ServiceInstalled true when docker service is present' {
            Mock -CommandName Get-Service -MockWith {[pscustomobject]@{Name='Docker'}}
            $targetResource = Get-TargetResource @ResArgs
            $targetResource.ServiceInstalled | Should Be $true
        }

        It 'Returns ServiceInstalled false when docker service is missing' {
            Mock -CommandName Get-Service -MockWith {}
            $targetResource = Get-TargetResource @ResArgs
            $targetResource.ServiceInstalled | Should Be $false
        }
    }
    #endregion


    #region Function Test-TargetResource
    Describe "Test-TargetResource" {
        It 'Returns false when docker service is missing and ensure is Present' {
            Mock -CommandName Get-Service -MockWith {}
            Test-TargetResource @ResArgs | Should Be $false
        }

        It 'Returns false when docker service is present and ensure is Absent' {
            Mock -CommandName Get-Service -MockWith {[pscustomobject]@{Name='Docker'}}
            $TestArg = $ResArgs.Clone()
            $TestArg.Ensure = 'Absent'
            Test-TargetResource @TestArg | Should Be $false
        }

        It 'Returns true when docker service is present and ensure is Present' {
            Mock -CommandName Get-Service -MockWith {[pscustomobject]@{Name='Docker'}}
            Test-TargetResource @ResArgs | Should Be $true
        }
    }
    #endregion
    
    #region Function Set-TargetResource
    Describe "Set-TargetResource" {
        It 'Should throw when path to dockerd is invalid' {
            Mock -CommandName Test-Path -MockWith {$false}
            {Set-TargetResource @ResArgs} | Should throw
        }

        It 'Should Register Docker Service when ensure is present' {
            Mock -CommandName Get-Service -MockWith {}
            Mock -CommandName Stop-Service -MockWith {}
            Mock -CommandName ResolveDockerDPath -MockWith {'c:\program files\docker\dockerd.exe'}
            Mock -CommandName DockerDReg -MockWith {}
            $null = Set-TargetResource @ResArgs
            Assert-MockCalled -CommandName Stop-Service -Exactly -Times 0
        }

        It 'Should stop Docker Service when present and ensure is absent' {
            Mock -CommandName Get-Service -MockWith {[pscustomobject]@{Name='Docker'}}
            Mock -CommandName Stop-Service -MockWith {}
            Mock -CommandName ResolveDockerDPath -MockWith {'c:\program files\docker\dockerd.exe'}
            Mock -CommandName DockerDReg -MockWith {}
            $SetArg = $ResArgs.Clone()
            $SetArg.Ensure = 'Absent'
            $null = Set-TargetResource @SetArg
            Assert-MockCalled -CommandName Stop-Service -Exactly -Times 1
        }
    }
    #endregion
}
#endregion
