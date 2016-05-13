workflow Wait-VMKVPValue {

    [OutputType([PSCustomObject])]

    param (
        [Parameter(Mandatory)]
        [string] $HyperVHost,

        [Parameter(Mandatory)]
        [Pscredential] $HyperVCred,

        [Parameter(Mandatory)]
        [String] $VMName,

        [Parameter(Mandatory)]
        [String] $Key,

        [String] $Value
    )

    $OutputObj = [PSCustomObject] @{}

    Write-Verbose -Message 'Running Runbook: Get-VMKVPValue'
    Write-Verbose -Message "HyperVHost: $HyperVHost"
    Write-Verbose -Message "HyperVCred: $($HyperVCred.UserName)"
    Write-Verbose -Message "VMName: $VMName"
    Write-Verbose -Message "Key: $Key"
    Write-Verbose -Message "Value: $Value"

    try {
        $Result = inlinescript {
            $ErrorActionPreference = 'Stop'
            $VerbosePreference = [System.Management.Automation.ActionPreference]$Using:VerbosePreference
            $DebugPreference = [System.Management.Automation.ActionPreference]$Using:DebugPreference 

            Write-Verbose -Message "Setting up CIMSession with Hyper-V host: $using:HyperVHost"
            $CimSession = New-CimSession -ComputerName $using:HyperVHost -Credential $using:HyperVCred

            function Get-KVPValue {
                param (
                    $CimSession,
                    $VMName,
                    $Key
                )

                Get-CimInstance -Namespace root/virtualization/v2 -ClassName Msvm_ComputerSystem -Filter "elementname = '$VMName'" -CimSession $CimSession | 
                    Get-CimAssociatedInstance -ResultClassName Msvm_KvpExchangeComponent |  ForEach-Object {
                        $_ | Select-Object -ExpandProperty GuestExchangeItems |  ForEach-Object {
                                $XML = ([XML]$_).INSTANCE.PROPERTY
                                if (($XML| Where-Object { $_.Name -eq 'Name' }).value -eq $Key) {
                                    ($XML | Where-Object { $_.Name -eq 'Data' }).value
                                }
                            }
                        }
            } # function Get-KVPValue

            #Timeout of 360 * 5 = 1800 /60 = 30 Minutes
            [int]$timeout = 0
            if ($using:Value) {
                while (($V = Get-KVPValue -CimSession $CimSession -VMName $using:VMName -Key $using:Key) -ne $using:Value -and $timeout -ne 360) {
                    $timeout++
                    Start-Sleep -Seconds 5
                }
            }
            else {
                
                while (($V = Get-KVPValue -CimSession $CimSession -VMName $using:VMName -Key $using:Key) -eq $null -and $timeout -ne 360) {
                    $timeout++
                    Start-Sleep -Seconds 5
                }
                if ($V -eq $null) {
                    throw 'No Value appeared within 30 minutes'
                }
            }
            $v | Out-String | Write-Verbose
            Write-Output -InputObject $V
            $CimSession | Remove-CimSession

        }
        Add-Member -InputObject $OutputObj -MemberType NoteProperty -Name 'VMName' -Value $VMName
        Add-Member -InputObject $OutputObj -MemberType NoteProperty -Name 'Key' -Value $Key
        Add-Member -InputObject $OutputObj -MemberType NoteProperty -Name 'Value' -Value $Result
    }
    catch {
        Add-Member -InputObject $OutputObj -MemberType NoteProperty -Name 'error' -Value $_.message
    }
    return $OutputObj
}