workflow Set-CloudServiceStatus {

    [OutputType([PSCustomObject])]

    param (
        [Parameter(Mandatory)]
        [string] $VMRoleID,

        [Parameter(Mandatory)]
        [string] $VMMServer,

        [Parameter(Mandatory)]
        [pscredential] $VMMCreds,

        [string] $ServiceInstanceId,

        [bool] $Provisioning,

        [bool] $Provisioned,

        [bool] $Failed
    )

    Write-Verbose -Message 'Running Runbook: Set-CloudServiceStatus'
    Write-Verbose -Message "VMRoleID: $VMRoleID"
    Write-Verbose -Message "VMMServer: $VMMServer"
    Write-Verbose -Message "VMMCreds: $($VMMCreds.UserName)"
    Write-Verbose -Message "Provisioning: $Provisioning"
    Write-Verbose -Message "Provisioned: $Provisioned"
    Write-Verbose -Message "Failed: $Failed"

    $OutputObj = [PSCustomObject] @{}

    if ($ServiceInstanceId) {
        Write-Verbose -Message "ServiceInstanceId: $ServiceInstanceId"
    }

    try {
        if ($Provisioned -and $Provisioning) {
            Write-Error -Message 'Cannot state Provisioned and Provisioning at the same time' -ErrorAction Continue
            throw 'Cannot state Provisioned and Provisioning at the same time'
        }

        if ($Provisioned -and $Failed) {
            Write-Error -Message 'Cannot state Provisioned and Failed at the same time' -ErrorAction Continue
            throw 'Cannot state Provisioned and Failed at the same time'
        }

        if ($Provisioning -and $Failed) {
            Write-Error -Message 'Cannot state Provisioning and Failed at the same time' -ErrorAction Continue
            throw 'Cannot state Provisioning and Failed at the same time'
        }

        if ($Provisioned -or $Failed) {
            if (-not $ServiceInstanceId) {
                Write-Error -Message 'ServiceInstanceId not present, cannot update table to provisioned or failed state' -ErrorAction Continue
                throw 'ServiceInstanceId not present, cannot update table to provisioned or failed state'
            }
        }
        Add-Member -InputObject $OutputObj -MemberType NoteProperty -Name 'VMRoleID' -Value $VMRoleID

        Write-Verbose -Message 'Checking if VMM is clustered'
        [PSCustomObject]$ActiveNode = inlinescript {
            $ErrorActionPreference = 'Stop'
            $VerbosePreference = [System.Management.Automation.ActionPreference]$Using:VerbosePreference
            $DebugPreference = [System.Management.Automation.ActionPreference]$Using:DebugPreference 

            $InlineObj = [PSCustomObject]@{}

            Add-Member -InputObject $InlineObj -MemberType NoteProperty -Name 'ProcessId' -Value $PID -Force
            Add-Member -InputObject $InlineObj -MemberType NoteProperty -Name 'HostName' -Value "$env:COMPUTERNAME.$env:USERDNSDOMAIN" -Force

            Write-Verbose -Message 'Loading VMM Environmental data'
            $VMM = Get-SCVMMServer -ComputerName $Using:VMMServer

            Write-Verbose -Message 'Checking if VMM is deployed in HA'
            if ($VMM.IsHighlyAvailable) {
                Write-Debug -Message 'VMM is in HA, returning Active Node'
                Add-Member -InputObject $InlineObj -MemberType NoteProperty -Name 'VMMServer' -Value $VMM.ActiveVMMNode -Force
            }
            else {
                Write-Debug -Message 'VMM is not in HA, returning current Node'
                Add-Member -InputObject $InlineObj -MemberType NoteProperty -Name 'VMMServer' -Value $using:VMMServer -Force
            }

            return $InlineObj
        } -PSComputerName $VMMServer -PSCredential $VMMCreds -PSRequiredModules VirtualMachineManager

        if ($ActiveNode.ProcessId) {
            Stop-LingeringSession -ProcessId $ActiveNode.ProcessId -Server $ActiveNode.HostName -Credential $VMMCreds
        }

        Write-Verbose -Message 'Configuring CloudService provisioning status'
        [PSCustomObject]$ResultObj = inlinescript {
            $VerbosePreference=[System.Management.Automation.ActionPreference]$Using:VerbosePreference
            $DebugPreference=[System.Management.Automation.ActionPreference]$Using:DebugPreference
            $ErrorActionPreference = 'Stop'
            $InlineObj = [PSCustomObject]@{}

            Add-Member -InputObject $InlineObj -MemberType NoteProperty -Name 'ProcessId' -Value $PID -Force
            Add-Member -InputObject $InlineObj -MemberType NoteProperty -Name 'HostName' -Value "$env:COMPUTERNAME.$env:USERDNSDOMAIN" -Force

            Write-Verbose -Message 'Loading VMM Environmental data'
            $VMMConn = Get-SCVMMServer -ComputerName $Using:VMMServer

            $Resource = Get-CloudResource -Id $using:VMRoleID
            $ConnectionTimeout = 15
            $QueryTimeout = 600
            $BatchSize = 50000
            $ConnectionString = 'Server={0};Database={1};Integrated Security=True;Connect Timeout={2}' -f $VMMConn.DatabaseInstanceName, $VMMConn.DatabaseName, $ConnectionTimeout 
            $conn = New-Object -TypeName System.Data.SqlClient.SQLConnection
            $conn.ConnectionString = $ConnectionString
            $conn.Open()

            if ($using:Provisioning) {
                Write-Verbose -Message 'Enable Provisioning status'
                $TSQL = @"
                update dbo.tbl_WLC_ServiceInstance
                Set ObjectState = 6, VMRoleID = NULL
                OUTPUT INSERTED.ServiceInstanceId
                where VmRoleID = '$using:VMRoleID'
"@
                $command = New-Object -TypeName System.Data.SqlClient.SqlCommand
                $command.Connection = $conn
                $command.CommandText = $TSQL
                $reader = $command.ExecuteReader()
                while ($reader.Read()) {
                    $output = $reader.GetValue($1)
                }
                Add-Member -InputObject $InlineObj -MemberType NoteProperty -Name 'ServiceInstanceId' -Value $output.GUID -Force
            }

            elseif ($using:Provisioned) {
                Write-Verbose -Message 'Disable Provisioning status'
                $TSQL = @"
                update dbo.tbl_WLC_ServiceInstance
                Set ObjectState = 1, VMRoleID = '$using:VMRoleID'
               where ServiceInstanceId = '$using:ServiceInstanceId'
"@
                $command = New-Object -TypeName System.Data.SqlClient.SqlCommand
                $command.Connection = $conn
                $command.CommandText = $TSQL
                $null = $command.ExecuteNonQuery()

                Add-Member -InputObject $InlineObj -MemberType NoteProperty -Name 'ServiceInstanceId' -Value $using:ServiceInstanceId
            }

            elseif ($using:Failed) {
                Write-Verbose -Message 'Enable Fail status'
                $TSQL = @"
                update dbo.tbl_WLC_ServiceInstance
                Set ObjectState = 3, VMRoleID = '$using:VMRoleID'
                where ServiceInstanceId = '$using:ServiceInstanceId'
"@
                $command = New-Object -TypeName System.Data.SqlClient.SqlCommand
                $command.Connection = $conn
                $command.CommandText = $TSQL
                $null = $command.ExecuteNonQuery()

                Add-Member -InputObject $InlineObj -MemberType NoteProperty -Name 'ServiceInstanceId' -Value $using:ServiceInstanceId
            }
           
            $conn.Close()
            $conn.Dispose()

            $null = Get-CloudService -ID $Resource.CloudServiceId | Set-CloudService -RunREST
            return $InlineObj
        } -PSComputerName $ActiveNode.VMMServer -PSCredential $VMMCreds -PSRequiredModules VirtualMachineManager -PSAuthentication CredSSP
    }
    catch {
        Write-Error -Message "Exception happened in runbook Set-CloudServiceStatus: $($_.Message)" -ErrorAction Continue
        Add-Member -InputObject $OutputObj -MemberType NoteProperty -Name 'error' -Value $_.message
    }

    Add-Member -InputObject $OutputObj -MemberType NoteProperty -Name 'ServiceInstanceId' -Value $ResultObj.ServiceInstanceId -Force

    if ($ResultObj.ProcessId) {
        Stop-LingeringSession -ProcessId $ResultObj.ProcessId -Server $ResultObj.Hostname -Credential $VMMCreds
    }

    return $OutputObj
}