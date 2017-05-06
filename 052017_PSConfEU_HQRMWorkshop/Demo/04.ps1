# download code until now
Start-Process 'microsoft-edge:https://gist.github.com/bgelens/'

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet("Yes")]
        [System.String]
        $IsSingleInstance,

        [parameter(Mandatory = $true)]
        [System.Boolean]
        $Enable
    )

    return @{
        IsSingleInstance = 'Yes'
        Enable = Test-LMHostEnabled
    }
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.Boolean]
        $Enable
    )

    $Result = Invoke-CimMethod -ClassName Win32_NetworkAdapterConfiguration -MethodName EnableWINS -Arguments @{
        WINSEnableLMHostsLookup = $Enable
    }
    if ($Result.ReturnValue -ne '0')
    {
        throw "Configuring LMHOST lookup failed with ReturnValue $($Result.ReturnValue)"
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet("Yes")]
        [System.String]
        $IsSingleInstance,

        [parameter(Mandatory = $true)]
        [System.Boolean]
        $Enable
    )

    if ((Test-LMHostEnabled) -eq $Enable)
    {
        return $true
    }
    else
    {
        return $false
    }
}

# Helper Functions
function Test-LMHostEnabled
{
    [CmdletBinding()]
    param ()

    $CimInstance = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration -Filter 'IPEnabled = TRUE'
    Write-Verbose -Message "LMHost lookup enabled: $($CimInstance[0].WINSEnableLMHostsLookup)"
    $CimInstance[0].WINSEnableLMHostsLookup
}


Export-ModuleMember -Function *-TargetResource