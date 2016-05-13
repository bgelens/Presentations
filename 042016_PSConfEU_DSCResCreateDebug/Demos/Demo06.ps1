function Get-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        [parameter(Mandatory = $true)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [parameter(Mandatory = $true)]
        [System.String]
        $Name
    )

    $Share = Get-SmbShare -Name $Name -ErrorAction SilentlyContinue
    if ($share) {
        $Ensure = 'Present'
        $FullAccess = ($Share| Get-SmbShareAccess | ?{$_.AccessRight -eq 'Full'}).AccountName
    } else {
        $Ensure = 'Absent'
        $FullAccess = $null
    }
    return @{
        Name = $Name
        Ensure = $Ensure
        FullAccess = $FullAccess
    }
}

function Set-TargetResource {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [System.String]
        $Path,

        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [System.String[]]
        $FullAccess
    )
    $Share = Get-SmbShare -Name $Name -ErrorAction SilentlyContinue

    if ($null -ne $share) {
        Write-Verbose -Message "Share with name: $Name exists"
    } else {
        Write-Verbose -Message "Share with name: $Name does not exist"
    }

    if ($Ensure -eq 'Present') {
        if (-not $Share) {
            Write-Verbose -Message "Creating share: $Name"
            [void]$PSBoundParameters.Remove('Ensure')
            [void]$PSBoundParameters.Remove('Debug')
            [void]$PSBoundParameters.Remove('Verbose')
            $null = New-SmbShare @PSBoundParameters
        } elseif ($FullAccess) {
            Write-Verbose -Message "Resetting share Full Access permissions"
            $smbshareAccess = Get-SmbShareAccess -Name $Name
            $smbshareAccess | 
                Where-Object -FilterScript {$_.AccessControlType  -eq 'Allow' -and $_.AccessRight -eq 'Full'} | 
                    ForEach-Object -Process {
                        $Share | Revoke-SmbShareAccess -AccountName $_.AccountName -Force
                    }

            $FullAccess | ForEach-Object -Process {
                $Share | Grant-SmbShareAccess -AccountName $_ -AccessRight Full
            }
        }
    }
    
    if ($Ensure -eq 'Absent' -and $Share) {
        $Share | Remove-SmbShare -Force
    }
}


function Test-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [parameter(Mandatory = $true)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [System.String]
        $Path,

        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [System.String[]]
        $FullAccess
    )

    $Share = Get-SmbShare -Name $ShareName
    if ($share) {
        $ShareAccess = $share | Get-SmbShareAccess | Where-Object -FilterScript {$_.AccessRight -eq 'Full'}
    }
    if ($Ensure -eq 'Present') {
        Write-Verbose -Message "Share should be present"
        if (-not $Share) {
            Write-Verbose -Message "Share is NOT present"
            return $false
        }
        Write-Verbose -Message "Share is present"
        Write-Verbose -Message "Verifying FullAccess permissions"
        $Compare = @()
        foreach ($A in $ShareAccess.Account) {
            if ($A.split('\')[0] -ieq 'builtin') {
                if ($FullAccess -contains $A.split('\')[1]) {
                    $Compare += $A.split('\')[1]
                } elseif ($FullAccess -contains $A) {
                    $Compare += $A
                } else {
                    Write-Verbose -Message "FullAccess permissions are NOT in desired state"
                    return $false
                }
            } else {
                $Compare += $A
            }
        }
        if ($null -eq (Compare-Object -ReferenceObject $Compare -DifferenceObject $FullAccess)) {
            Write-Verbose -Message "FullAccess permissions are in desired state"
            return $true
        } else {
            Write-Verbose -Message "FullAccess permissions are NOT in desired state"
            return $false
        }
    }
    if ($Ensure -eq 'Absent') {
        Write-Verbose -Message "Share should NOT be present"
        if ($Share) {
            Write-Verbose -Message "Share is present"
            return $false
        } else {
            Write-Verbose -Message "Share is not present"
            return $true
        }
    }
}

Export-ModuleMember -Function *-TargetResource
