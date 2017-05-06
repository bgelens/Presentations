# add localization files
New-Item -Path .\NetworkingDsc\DSCResources\MSFT_LMHost -Name en-US -ItemType Directory
New-Item -Path .\NetworkingDsc\DSCResources\MSFT_LMHost\en-US -Name MSFT_LMHost.psd1

# content
# culture="en-US"
ConvertFrom-StringData -StringData @'
    GettingLMHostMessage = Getting LMHost Lookup state.
    SettingLMHostMessage = Setting LMHost Lookup setting to {0}.
    TestingLMHostMessage = Testing LMHost Lookup Enabled.
    InvalidLMHostUpdateError = Configuring LMHOST lookup failed with ReturnValue {0}.    
'@

# update resource code https://gist.github.com/bgelens
#region localizeddata
if (Test-Path "${PSScriptRoot}\${PSUICulture}")
{
    Import-LocalizedData `
        -BindingVariable LocalizedData `
        -Filename MSFT_LMHost.psd1 `
        -BaseDirectory "${PSScriptRoot}\${PSUICulture}"
}
else
{
    #fallback to en-US
    Import-LocalizedData `
        -BindingVariable LocalizedData `
        -Filename MSFT_LMHost.psd1 `
        -BaseDirectory "${PSScriptRoot}\en-US"
}
#endregion

<#
    .SYNOPSIS
    Returns the current LMHost Lookup setting on the node.
    .PARAMETER IsSingleInstance
    Specifies the resource is a single instance, the value must be 'Yes'.
    .PARAMETER Enable
    Specifies if LMHost lookup should be enabled or not.
#>
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
    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($LocalizedData.GettingLMHostMessage)
        ) -join '' )

    return @{
        IsSingleInstance = 'Yes'
        Enable = Test-LMHostEnabled
    }
}

<#
    .SYNOPSIS
    Sets the desired LMHost Lookup setting on the node.
    .PARAMETER IsSingleInstance
    Specifies the resource is a single instance, the value must be 'Yes'.
    .PARAMETER Enable
    Specifies if LMHost lookup should be enabled or not.
#>
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
    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($LocalizedData.SettingLMHostMessage -f $Enable)
        ) -join '' )

    $Result = Invoke-CimMethod -ClassName Win32_NetworkAdapterConfiguration -MethodName EnableWINS -Arguments @{
        WINSEnableLMHostsLookup = $Enable
    }
    if ($Result.ReturnValue -ne '0')
    {
        New-TerminatingError `
            -errorId 'InvalidLMHostUpdateError' `
            -errorMessage ($LocalizedData.InvalidLMHostUpdateError -f $Result.ReturnValue) `
            -errorCategory InvalidResult
    }
}

<#
    .SYNOPSIS
    Tests if the current LMHost lookup setting on the node needs to be changed.
    .PARAMETER IsSingleInstance
    Specifies the resource is a single instance, the value must be 'Yes'.
    .PARAMETER Enable
    Specifies if LMHost lookup should be enabled or not.
    .OUTPUTS
    Returns false if the LMHost lookup setting needs to be changed or true if it is correct.
#>
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
    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($LocalizedData.TestingLMHostMessage)
        ) -join '' )

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
<#
    .SYNOPSIS
    Throw a custome exception.
    .PARAMETER ErrorId
    The identifier representing the exception being thrown.
    .PARAMETER ErrorMessage
    The error message to be used for this exception.
    .PARAMETER ErrorCategory
    The exception error category.
#>
function New-TerminatingError
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [String] $ErrorId,

        [Parameter(Mandatory)]
        [String] $ErrorMessage,

        [Parameter(Mandatory)]
        [System.Management.Automation.ErrorCategory] $ErrorCategory
    )

    $exception = New-Object `
        -TypeName System.InvalidOperationException `
        -ArgumentList $errorMessage
    $errorRecord = New-Object `
        -TypeName System.Management.Automation.ErrorRecord `
        -ArgumentList $exception, $errorId, $errorCategory, $null
    $PSCmdlet.ThrowTerminatingError($errorRecord)
}

<#
    .SYNOPSIS
    Checks if LMHost lookup is currently enabled
#>
function Test-LMHostEnabled
{
    [CmdletBinding()]
    param ()

    $CimInstance = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration -Filter 'IPEnabled = TRUE'
    Write-Verbose -Message "LMHost lookup enabled: $($CimInstance[0].WINSEnableLMHostsLookup)"
    $CimInstance[0].WINSEnableLMHostsLookup
}


Export-ModuleMember -Function *-TargetResource

# Update Unit test
Describe "MSFT_LMHost\New-TerminatingError" {
    Context 'Create a TestError Exception' {
        It 'should throw an TestError exception' {
            $errorId = 'TestError'
            $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument
            $errorMessage = 'Test Error Message'
            $exception = New-Object `
                -TypeName System.InvalidOperationException `
                -ArgumentList $errorMessage
            $errorRecord = New-Object `
                -TypeName System.Management.Automation.ErrorRecord `
                -ArgumentList $exception, $errorId, $errorCategory, $null

            { New-TerminatingError `
                -ErrorId $errorId `
                -ErrorMessage $errorMessage `
                -ErrorCategory $errorCategory } | Should Throw $errorRecord
        }
    }
}

# completed example:
# https://psconfeu.blob.core.windows.net/demo/NetworkingDscFinal.zip