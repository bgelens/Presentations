# SH-02
$ModuleDir = Split-Path -Path (Get-Module -Name PSConfEU -ListAvailable).Path
$DSCResDir = Join-Path -Path $ModuleDir -ChildPath 'DSCResources'
$ResDir = (New-Item -Path $DSCResDir -Name RDSWaitForCollection -ItemType Directory).FullName
$psm1 = New-Item -Path $ResDir -Name RDSWaitForCollection.psm1 -ItemType File -Value @'
#requires -Module RemoteDesktop

[DscResource()]
class RDSWaitForCollection {
    [DSCProperty(Mandatory)]
    [string] $ConnectionBroker

    [DSCProperty(Key)]
    [string] $Name

    [DSCProperty()]
    [uint64] $RetryIntervalSec = 60

    [DSCProperty()]
    [uint32] $RetryCount

    [RDSWaitForCollection] Get () {
        $obj = [RDSWaitForCollection]::new()
        $obj.ConnectionBroker = $this.ConnectionBroker
        $obj.Name = $this.Name
        $obj.RetryCount = $this.RetryCount
        $obj.RetryIntervalSec = $this.RetryIntervalSec
        return $obj
    }

    [bool] Test () {
        return $this.TestCollectionAvailable($this.ConnectionBroker,$this.Name)
    }

    [void] Set () {
        for ($i = 0; $i -lt $this.RetryCount; $i++) {
            $CollectionPresent = $this.TestCollectionAvailable($this.ConnectionBroker,$this.Name)
            if (!$CollectionPresent) {
                Write-Verbose -Message "Collection $($this.Name) is not available. Will retry again after $($this.RetryIntervalSec) sec"
                Start-Sleep -Seconds $this.RetryIntervalSec
            } else {
                break
            }
        }
        $Result = $this.TestCollectionAvailable($this.ConnectionBroker,$this.Name)
        if (!$Result) {
            Write-Verbose -Message "Collection $($this.Name) is not available. No more retries will be attempted"
            throw "Collection $($this.Name) is not available. No more retries will be attempted"
        }
    }

    [bool] TestCollectionAvailable ([string]$ConnectionBroker,[string]$Name) {
        try {
            $CollectionPresent = Get-RDSessionCollection -ConnectionBroker $ConnectionBroker -CollectionName $Name -ErrorAction Stop
            if ($CollectionPresent) {
                return $true
            } else {
                return $false
            }
        } catch {
            return $false
        }
    }
}
'@ -Force
New-ModuleManifest -Path "$ResDir\RDSWaitForCollection.psd1" -RootModule RDSWaitForCollection.psm1 -ModuleVersion 1.0.0.0 -Author bgelens -CompanyName PSConfEU -DscResourcesToExport RDSWaitForCollection

Get-DscResource -Module PSConfEU

Update-ModuleManifest -Path $ModuleDir\PSConfEU.psd1 -PowerShellVersion 5.1 -DscResourcesToExport RDSWaitForCollection -NestedModules 'DSCResources\RDSWaitForCollection\RDSWaitForCollection.psd1'

Get-DscResource -Module PSConfEU

psEdit $ResDir\RDSWaitForCollection.psm1

Invoke-DscResource -ModuleName PSConfEU -Name RDSWaitForCollection -Method Set -Verbose -Property @{
    ConnectionBroker = 'cb-01.psconf.eu'
    Name = 'PSConfEU'
    PsDscRunAsCredential =  [pscredential]::new('PSConfEU\Administrator',(ConvertTo-SecureString 'Welkom01' -AsPlainText -Force))
}

Move-Item `
    -Path C:\Windows\System32\config\systemprofile\AppData\Local\dsc\PSConfEU.1.0.RDSWaitForCollection.schema.mof `
    -Destination C:\Windows\System32\config\systemprofile\AppData\Local\dsc\RDSWaitForCollection.1.0.RDSWaitForCollection.schema.mof

Enable-DscDebug -BreakAll
Disable-DscDebug

#region create final resource to join collection
New-xDscResource -Name PSConfEU_RDSCollectionMember -Path 'C:\Program Files\WindowsPowerShell\Modules'-ModuleName PSConfEU -FriendlyName RDSCollectionMember -ClassVersion 1.0.0.0 -Property @(
    New-xDscResourceProperty -Name ConnectionBroker -Type String -Attribute Required
    New-xDscResourceProperty -Name CollectionName -Type String -Attribute Key
    New-xDscResourceProperty -Name Ensure -Type String -Attribute Required -ValidateSet 'Present','Absent'
) -Force

@'
Import-Module RemoteDesktop
$localhost = [System.Net.Dns]::GetHostByName((hostname)).HostName

function Get-TargetResource {
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param (
        [parameter(Mandatory)]
        [string] $CollectionName,

        [parameter(Mandatory)]
        [string] $ConnectionBroker,

        [parameter(Mandatory)]
        [ValidateSet("Present","Absent")]
        [string] $Ensure
    )

    $Collection = Get-RDSessionHost `
        -CollectionName $CollectionName `
        -ConnectionBroker $ConnectionBroker `
        -ErrorAction Stop

    if ($Collection.SessionHost -notcontains $script:localhost) {
        Write-Verbose -Message "$script:localhost is not a member of Collection: $CollectionName"
        $Ensure = 'Absent'
    } else {
        Write-Verbose -Message "$script:localhost is a member of Collection: $CollectionName"
        $Ensure = 'Present'
    }
    return @{
        Ensure = $Ensure
        CollectionName = $CollectionName
        ConnectionBroker = $ConnectionBroker
    }
}


function Set-TargetResource {
    [CmdletBinding()]
    param (
        [parameter(Mandatory)]
        [string] $CollectionName,

        [parameter(Mandatory)]
        [string] $ConnectionBroker,

        [parameter(Mandatory)]
        [ValidateSet("Present","Absent")]
        [string] $Ensure
    )
    if ($Ensure -eq 'Present') {
        Add-RDSessionHost `
            -SessionHost $script:localhost `
            -ConnectionBroker $ConnectionBroker `
            -CollectionName $CollectionName
    } else {
        Remove-RDSessionHost `
            -ConnectionBroker $ConnectionBroker `
            -SessionHost $script:localhost `
            -Force
    }
}


function Test-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [parameter(Mandatory)]
        [string] $CollectionName,

        [parameter(Mandatory)]
        [string] $ConnectionBroker,

        [parameter(Mandatory)]
        [ValidateSet("Present","Absent")]
        [string] $Ensure
    )
    $Get = Get-TargetResource `
        -CollectionName $CollectionName `
        -ConnectionBroker $ConnectionBroker `
        -Ensure $Ensure
    [void]$PSBoundParameters.Remove("Verbose")
    [void]$PSBoundParameters.Remove("Debug")
    $BoundParams = $PSBoundParameters
    $Check = $true
    $BoundParams.Keys | ForEach-Object -Process {
        $Key = $_
        if ($BoundParams[$Key] -ne $Get[$Key]) {
            Write-Verbose -Message "$Key should be $($BoundParams[$Key]) but is $($Get[$Key])"
            $Check = $false
        }
    }
    $Check
}


Export-ModuleMember -Function *-TargetResource


'@ | Out-File -FilePath "$DSCResDir\PSConfEU_RDSCollectionMember\PSConfEU_RDSCollectionMember.psm1" -Encoding utf8 -Force
#endregion