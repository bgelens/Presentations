workflow Stop-LingeringSession {
    param (
        [Parameter(Mandatory)]
        [Int] $ProcessId,

        [Parameter(Mandatory)]
        [String] $Server,

        [Parameter(Mandatory)]
        [PSCredential] $Credential
    )

    try {
        $Null = inlinescript {
            $CimSession = New-CimSession -ComputerName $using:Server -Authentication CredSsp -Credential $using:Credential
            if ($process = Get-CimInstance -ClassName win32_process -CimSession $CimSession -Filter "ProcessId = '$using:ProcessId'") {
                $process | Invoke-CimMethod -MethodName terminate | Out-Null
            }
            $CimSession | Remove-CimSession
        }
    }
    catch {
        # Do nothing
    }
}