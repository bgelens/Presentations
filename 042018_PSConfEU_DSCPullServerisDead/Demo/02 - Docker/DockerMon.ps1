$configFile = 'C:\inetpub\PSDSCPullServer\web.config'
$connString = $env:ConnectionString
if ($null -eq $connString) {
    # could also result in edb usage instead of sql so container can run in solo mode
    Write-Error -Message 'No ConnectionString found in Environment variables' -ErrorAction Stop
}
$webConfig = Get-Content -Path $configFile
$webConfig = $webConfig.replace('#CONNECTIONSTRING#', $connString)
if (Test-Path -Path c:\pullserver) {
    # if it doesn't keep defaults to at least be able to run
    $webConfig = $webConfig.replace('C:\Program Files\WindowsPowerShell\DscService', 'c:\pullserver')
}
$webConfig | Set-Content $configFile

Start-Website -Name PSDSCPullServer

function Monitor {
    $irmArgs = @{
        Headers = @{
            Accept = 'application/json'
            ProtocolVersion = '2.0'
        }
        UseBasicParsing = $true
        Uri = 'http://localhost:8080/PSDSCPullServer.svc'
        ErrorAction = 'Stop'
    }
    try {
        Invoke-RestMethod @irmArgs
        Start-Sleep -Seconds 10
        Monitor
    } catch {
        throw $_
    }
}

Monitor