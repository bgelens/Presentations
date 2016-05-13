workflow Add-InstallSourceDisk {
    
    [OutputType([PSCustomObject])]

    param (
        [Parameter(Mandatory)]
        [string] $HyperVHost,

        [Parameter(Mandatory)]
        [Pscredential] $HyperVCred,

        [Parameter(Mandatory)]
        [String] $VMName,

        [Parameter(Mandatory)]
        [String] $InstallDisk
    )

    $OutputObj = [PSCustomObject] @{}

    Write-Verbose -Message 'Running Runbook: Add-InstallSourceDisk'
    Write-Verbose -Message "HyperVHost: $HyperVHost"
    Write-Verbose -Message "HyperVCred: $($HyperVCred.UserName)"
    Write-Verbose -Message "VMName: $VMName"
    Write-Verbose -Message "InstallDisk: $InstallDisk"

    try {
        $ResultObj = inlinescript {
            $ErrorActionPreference = 'Stop'
            $VerbosePreference = [System.Management.Automation.ActionPreference]$Using:VerbosePreference
            $DebugPreference = [System.Management.Automation.ActionPreference]$Using:DebugPreference

            $InlineObj = [PSCustomObject]@{}

            if (Test-Path "C:\$using:InstallDisk") {
                Add-Member -InputObject $InlineObj -MemberType NoteProperty -Name 'Exist' -Value $true -Force

                $DiffDisk = New-VHD -ParentPath "C:\$using:InstallDisk" -Path "C:\Hyper-V\$using:VMName\$using:InstallDisk" -Differencing

                $VHDAdd = Add-VMHardDiskDrive -Path "C:\Hyper-V\$using:VMName\$using:InstallDisk" -Passthru -VMName $using:VMName -ControllerType SCSI -ControllerNumber 0 -ControllerLocation 0
                if ($VHDAdd) {
                    Add-Member -InputObject $InlineObj -MemberType NoteProperty -Name 'Attached' -Value $true -Force
                }
                else {
                    Add-Member -InputObject $InlineObj -MemberType NoteProperty -Name 'Attached' -Value $false -Force
                }
            }
            else {
                Add-Member -InputObject $InlineObj -MemberType NoteProperty -Name 'Exist' -Value $false -Force
            }
            return $InlineObj
        } -PSComputerName $HyperVHost -PSCredential $HyperVCred
    }
    catch {
        Add-Member -InputObject $OutputObj -MemberType NoteProperty -Name 'error' -Value $_.message
    }

    Add-Member -InputObject $OutputObj -MemberType NoteProperty -Name 'Exist' -Value $ResultObj.Exist -Force
    Add-Member -InputObject $OutputObj -MemberType NoteProperty -Name 'Attached' -Value $ResultObj.Attached -Force

    return $OutputObj
}