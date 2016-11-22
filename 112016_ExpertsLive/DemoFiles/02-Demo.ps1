#region xDSCResourceDesigner
Get-Module xDSCResourceDesigner -ListAvailable
Get-Command -Module xDSCResourceDesigner
#endregion

#region live develop DSC resource
New-xDscResource -Name EL_DockerD -Path 'C:\Program Files\WindowsPowerShell\Modules'-ModuleName ExpertsLive -FriendlyName DockerD -ClassVersion 1.0.0.0 -Property @(
    New-xDscResourceProperty -Name 'Ensure' -Type String -Attribute Required -ValidateSet 'Present','Absent'
    New-xDscResourceProperty -Name 'Path' -Type String -Attribute Key
    New-xDscResourceProperty -Name 'ServiceInstalled' -Type Boolean -Attribute Read
) -Force
#endregion

#region update Test so we can start
Get-ChildItem -Path (Get-DscResource -Module ExpertsLive).ParentPath -Filter * | %{psEdit $_.FullName}
    # change string param to int
    Test-xDscResource -Name EL_DockerD -Verbose
    # undo change string param to int
    Test-xDscResource -Name EL_DockerD -Verbose

    # change schema remove key
    Test-xDscSchema -Path 'C:\Program Files\WindowsPowerShell\Modules\ExpertsLive\DSCResources\EL_DockerD\EL_DockerD.schema.mof' -Verbose
    # undo change schema remove key
    Test-xDscSchema -Path 'C:\Program Files\WindowsPowerShell\Modules\ExpertsLive\DSCResources\EL_DockerD\EL_DockerD.schema.mof' -Verbose

    # Update Test
    # Write-Verbose -Message "Bound Params: $($PSBoundParameters | Out-String)"
    # Write-Verbose -Message "Running as: $(whoami.exe)"
    # return $true
#endregion