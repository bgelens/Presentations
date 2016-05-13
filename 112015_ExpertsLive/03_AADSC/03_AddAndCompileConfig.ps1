$SolutionDir = $DTE.ActiveDocument.Path

#region go to PowerShell Gallery
start microsoft-edge:http://powershellgallery.com/
$AAAccount | Get-AzureRmAutomationModule -Name xCredSSP
#endregion go to PowerShell Gallery

#region config for EL201502
{
configuration CredSSP {
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xCredSSP
    node AllServers {
        xCredSSP Server {
            Ensure = 'Present'
            Role = 'Server'
        }
        xCredSSP Client {
            Ensure = 'Present'
            Role = 'Client'
            DelegateComputers = '*.EL2015.local'
        }
    }
}
}.Ast.EndBlock.Extent.Text | Out-File $SolutionDir\CredSSP.ps1 -Force -Encoding ascii
#endregion config for EL2015E02

#region import config to AADSC
$CredSSPScript = $AAAccount | Import-AzureRmAutomationDscConfiguration -Path "$SolutionDir\CredSSP.ps1" -Force -Published
$CredSSPScript
#endregion import config to AADSC

#region compile MOF
$Job = $CredSSPScript | Start-AzureRmAutomationDscCompilationJob
while ($null -eq $Job.EndTime -and $null -eq $job.Exception) {
    $Job = $Job | Get-AzureRmAutomationDscCompilationJob
    Write-Verbose $Job.Status -Verbose
    Start-Sleep -Seconds 3
}
$Job
$Job | Get-AzureRmAutomationDscCompilationJobOutput
#endregion compile MOF

#region assign config to node
$Node = $AAAccount | Get-AzureRmAutomationDscNode -Name EL201502
$AAAccount | Get-AzureRmAutomationDscNodeConfiguration #bug in current PS Module (name is not returned) Show portal
$AAAccount | Set-AzureRmAutomationDscNode -Id $Node.Id -NodeConfigurationName "$($CredSSPScript.Name).AllServers" -Force
$Node | Get-AzureRmAutomationDscNode

# go in VM and Update-DscConfiguration as we don't have 15 min
$EL201502Session | Enter-PSSession
Update-DscConfiguration -Wait -Verbose
#show CredSSP config and Get-DscConfigurartion
#Exit-Pssession

$AAAccount | Get-AzureRmAutomationDscNodeReport -NodeId $Node.Id
#endregion assign config to node