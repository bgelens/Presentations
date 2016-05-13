workflow Get-VMRoleVMs {

    [OutputType([PSCustomObject])]

    param (
        [Parameter(Mandatory=$true)]
        [string] $VMRoleId,

        [Parameter(Mandatory=$True)]
        [String] $VMMServer,

        [Parameter(Mandatory=$True)]
        [PSCredential] $VMMCreds
    )

    $OutputObj = [PSCustomObject] @{}

    Write-Verbose -Message 'Running Runbook: Get-VMRoleVMs'
    Write-Verbose -Message "VMRoleId: $VMRoleId"
    Write-Verbose -Message "VMMServer: $VMMServer"
    Write-Verbose -Message "VMMCreds: $($VMMCreds.UserName)"

    try {
        $Result = inlinescript {
            $ErrorActionPreference = 'Stop'
            $VerbosePreference=[System.Management.Automation.ActionPreference]$Using:VerbosePreference
            $DebugPreference=[System.Management.Automation.ActionPreference]$Using:DebugPreference
            Write-Verbose -Message 'Loading VMM Environmental data'
            Get-SCVMMServer -ComputerName $Using:VMMServer -ErrorAction Stop | Out-Null

            #Wait until VMs are present in cloudresource or until 3 minutes have passed
            $i = 0
            while (!((Get-CloudResource -Id $using:VMRoleId).VMs) -or $i -ne 36) {
                $i++
                Write-Debug 'Wait for VMs to be added to cloudresource'
                Start-Sleep -Seconds 5
            }

            $VMs = (Get-CloudResource -Id $using:VMRoleId).VMs
            if ($VMs) {
                Write-Output -InputObject $VMs
            }
            else {
                throw 'Failed Resolving VMRole VMs within 3 minutes'
            }
        } -PSComputerName $VMMServer -PSCredential $VMMCreds -PSRequiredModules VirtualMachineManager -PSDisableSerialization $true
        Add-Member -InputObject $OutputObj -MemberType NoteProperty -Name 'VMs' -Value $Result
    }
    catch {
        Add-Member -InputObject $OutputObj -MemberType NoteProperty -Name 'error' -Value $_.message
    }
    
    return $OutputObj
}