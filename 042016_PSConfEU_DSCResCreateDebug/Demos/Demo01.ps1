#region xDSCResourceDesigner
Get-Module xDSCResourceDesigner -ListAvailable
Get-Command -Module xDSCResourceDesigner
#endregion

#region live develop DSC resource (xSMBShare already exists but good example and works on Nano :-) )
New-xDscResource -Name PSConfEU_SMBShare -Path 'C:\Program Files\WindowsPowerShell\Modules'-ModuleName PSConfEU -FriendlyName SMBShare -ClassVersion 1.0.0.0 -Property @(
    New-xDscResourceProperty -Name 'Ensure' -Type String -Attribute Required -ValidateSet 'Present','Absent'
    New-xDscResourceProperty -Name 'Path' -Type String -Attribute Write
    New-xDscResourceProperty -Name 'Name' -Type String -Attribute Key
    New-xDscResourceProperty -Name 'FullAccess' -Type String[] -Attribute Write
) -Force
#endregion

#region update Test so we can start
Get-ChildItem -Path (Get-DscResource -Module PSConfEU).ParentPath -Filter * | %{psEdit $_.FullName}
    # change string param to int
    Test-xDscResource -Name SMBShare -Verbose
    # undo change string param to int
    Test-xDscResource -Name SMBShare -Verbose

    # change schema remove key
    Test-xDscSchema -Path 'C:\Program Files\WindowsPowerShell\Modules\PSConfEU\DSCResources\PSConfEU_SMBShare\PSConfEU_SMBShare.schema.mof' -Verbose
    # undo change schema remove key
    Test-xDscSchema -Path 'C:\Program Files\WindowsPowerShell\Modules\PSConfEU\DSCResources\PSConfEU_SMBShare\PSConfEU_SMBShare.schema.mof' -Verbose

    # Update Test
    # Write-Verbose -Message "Bound Params: $($PSBoundParameters | Out-String)"
    # Write-Verbose -Message "Running as: $(whoami.exe)"
    # return $true
#endregion