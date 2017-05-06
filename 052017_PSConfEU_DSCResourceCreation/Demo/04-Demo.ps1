# SH-02
# first make sure LCM is doing nothing
Move-Item C:\windows\System32\Configuration\MetaConfig.mof C:\windows\System32\Configuration\MetaConfig.mof.old
Move-Item C:\windows\System32\Configuration\MetaConfig.backup.mof C:\windows\System32\Configuration\MetaConfig.backup.mof.old
Get-PSHostProcessInfo | ? AppDomainName -eq DscPsPluginWkr_AppDomain | kill -Force

# use script resource
Invoke-DscResource -ModuleName PSDesiredStateConfiguration -Name Script -Method Test -Verbose -Property @{
    GetScript = {
        @{
            GetScript = $GetScript
            SetScript = $SetScript
            TestScript = $TestScript
        }
    }
    SetScript = {
        for ($i = 0; $i -lt 10; $i++) {
            try {
                $RoleAvailable = Get-RDServer -Role "RDS-CONNECTION-BROKER" -ConnectionBroker 'cb-01.psconf.eu' -ErrorAction Stop
            } catch {}
            if (!$RoleAvailable) {
                Write-Verbose -Message "Role $Role not available. Will retry again after $RetryIntervalSec sec"
                Start-Sleep -Seconds 60
            } else {
                break
            }
        }
        try {
            $Result = Get-RDServer -Role "RDS-CONNECTION-BROKER" -ConnectionBroker 'cb-01.psconf.eu' -ErrorAction Stop
        } catch { }
        if (!$Result) {
            Write-Verbose -Message "Role $Role not available. No more retries will be attempted"
            throw "Role $Role not available. No more retries will be attempted"
        }
    }
    TestScript = {
        try {
            $RolePresent = Get-RDServer -Role "RDS-CONNECTION-BROKER" -ConnectionBroker 'cb-01.psconf.eu' -ErrorAction Stop
        } catch { }
        if ($RolePresent) {
            $true
        } else {
            $false
        }
    }
    PsDscRunAsCredential =  [pscredential]::new('PSConfEU\Administrator',(ConvertTo-SecureString 'Welkom01' -AsPlainText -Force))
}

#redundant code, no params and hard to debug and test!
Enable-DscDebug -BreakAll
Disable-DscDebug

# better to create custom resource
Install-Module xDSCResourceDesigner -Force -Verbose

New-xDscResource -Name PSConfEU_RDSWaitForRole -Path 'C:\Program Files\WindowsPowerShell\Modules'-ModuleName PSConfEU -FriendlyName RDSWaitForRole -ClassVersion 1.0.0.0 -Property @(
    New-xDscResourceProperty -Name ConnectionBroker -Type String -Attribute Required
    New-xDscResourceProperty -Name Role -Type String -Attribute Key -ValidateSet 'RDS-CONNECTION-BROKER','RDS-GATEWAY','RDS-LICENSING','RDS-RD-SERVER','RDS-VIRTUALIZATION','RDS-WEB-ACCESS'
    New-xDscResourceProperty -Name RetryIntervalSec -Attribute Write -Type Uint64
    New-xDscResourceProperty -Name RetryCount -Attribute Write -Type Uint32
) -Force

Get-DscResource -Module PSConfEU
psedit (Get-DscResource -Module PSConfEU -Name RDSWaitForRole).Path

#region resource code
Import-Module RemoteDesktop

function Get-TargetResource {
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param (
        [parameter(Mandatory)]
        [string] $ConnectionBroker,

        [parameter(Mandatory)]
        [ValidateSet("RDS-CONNECTION-BROKER","RDS-GATEWAY","RDS-LICENSING","RDS-RD-SERVER","RDS-VIRTUALIZATION","RDS-WEB-ACCESS")]
        [string] $Role,

        [UInt64] $RetryIntervalSec = 60,

        [UInt32] $RetryCount = 10
    )
    return @{
        ConnectionBroker = $ConnectionBroker
        Role = $Role
        RetryIntervalSec = $RetryIntervalSec
        RetryCount = $RetryCount
    }

}


function Set-TargetResource {
    [CmdletBinding()]
    param (
        [parameter(Mandatory)]
        [string] $ConnectionBroker,

        [parameter(Mandatory)]
        [ValidateSet("RDS-CONNECTION-BROKER","RDS-GATEWAY","RDS-LICENSING","RDS-RD-SERVER","RDS-VIRTUALIZATION","RDS-WEB-ACCESS")]
        [string] $Role,

        [UInt64] $RetryIntervalSec = 60,

        [UInt32] $RetryCount = 10
    )
    for ($i = 0; $i -lt $RetryCount; $i++) {
        $RoleAvailable = TestRoleAvailable -ConnectionBroker $ConnectionBroker -Role $Role
        if (!$RoleAvailable) {
            Write-Verbose -Message "Role $Role not available. Will retry again after $RetryIntervalSec sec"
            Start-Sleep -Seconds $RetryIntervalSec
        } else {
            break
        }
    }
    $Result = TestRoleAvailable -ConnectionBroker $ConnectionBroker -Role $Role
    if (!$Result) {
        Write-Verbose -Message "Role $Role not available. No more retries will be attempted"
        throw "Role $Role not available. No more retries will be attempted"
    }
}


function Test-TargetResource {
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [parameter(Mandatory)]
        [string] $ConnectionBroker,

        [parameter(Mandatory)]
        [ValidateSet("RDS-CONNECTION-BROKER","RDS-GATEWAY","RDS-LICENSING","RDS-RD-SERVER","RDS-VIRTUALIZATION","RDS-WEB-ACCESS")]
        [string] $Role,

        [UInt64] $RetryIntervalSec = 60,

        [UInt32] $RetryCount = 10
    )
    TestRoleAvailable -ConnectionBroker $ConnectionBroker -Role $Role
}

function TestRoleAvailable {
    param (
        [parameter(Mandatory)]
        [string] $ConnectionBroker,

        [parameter(Mandatory)]
        [ValidateSet("RDS-CONNECTION-BROKER","RDS-GATEWAY","RDS-LICENSING","RDS-RD-SERVER","RDS-VIRTUALIZATION","RDS-WEB-ACCESS")]
        [string] $Role
    )
    try {
        $RolePresent = Get-RDServer -Role $Role -ConnectionBroker $ConnectionBrokert -ErrorAction Stop
        if ($RolePresent) {
            return $true
        } else {
            return $false
        }
    } catch {
        return $false
    }
}


Export-ModuleMember -Function *-TargetResource


#endregion

Invoke-DscResource -ModuleName PSConfEU -Name RDSWaitForRole -Method Set -Verbose -Property @{
    ConnectionBroker = 'cb-01.psconf.eu'
    Role = 'RDS-CONNECTION-BROKER'
    PsDscRunAsCredential =  [pscredential]::new('PSConfEU\Administrator',(ConvertTo-SecureString 'Welkom01' -AsPlainText -Force))
}

Get-PSHostProcessInfo | ? AppDomainName -eq DscPsPluginWkr_AppDomain | kill -Force
Enable-DscDebug -BreakAll

#fix code and try again :)

Disable-DscDebug

# let's do the same with waiting for the collection but this time as a class resource

