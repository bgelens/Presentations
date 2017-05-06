# fix meta issues
ipmo .\NetworkingDsc\DSCResource.Tests\MetaFixers.psm1 -Verbose
Get-Item -Path .\NetworkingDsc\NetworkingDsc.psd1 | ConvertTo-UTF8
Get-Item -Path .\NetworkingDsc\DSCResources\MSFT_LMHost\MSFT_LMHost.psm1 | ConvertTo-UTF8
Get-Item -Path .\NetworkingDsc\DSCResources\MSFT_LMHost\MSFT_LMHost.schema.mof | ConvertTo-ASCII

# fix code content
@'
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
    Write-Verbose -Message "Get TargetResource"
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
        [ValidateSet("Yes")]
        [System.String]
        $IsSingleInstance,

        [parameter(Mandatory = $true)]
        [System.Boolean]
        $Enable
    )
    Write-Verbose -Message "Set TargetResource"
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
    Write-Verbose -Message "Test TargetResource"
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

'@ | Set-Clipboard #not that extra endline!

# fix manifest
Update-ModuleManifest -Path .\NetworkingDsc\NetworkingDsc.psd1 -PowerShellVersion "4.0"

# download until here:
# https://psconfeu.blob.core.windows.net/demo/NetworkingDsc01.zip