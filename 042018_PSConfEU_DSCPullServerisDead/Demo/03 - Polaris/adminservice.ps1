$connString = $env:ConnectionString
if ($null -eq $connString) {
    Write-Error -Message 'No ConnectionString found in Environment variables' -ErrorAction Stop
}

Import-Module .\Polaris\Polaris.psd1
ipmo .\DSCPullServerAdmin.psm1

New-PolarisGetRoute -Path /dscreport -ScriptBlock {
    ipmo .\DSCPullServerAdmin.psm1
    if ($request.Query['name']) {
        $reports = Get-DscPullServerReport -Name $request.Query['name'] -ConnectionString $env:ConnectionString
    } else {
        $reports = Get-DscPullServerReport -ConnectionString $env:ConnectionString
    }
    if ($null -ne $reports) {
        $response.Json(($reports | ConvertTo-Json))
    } else {
        $response.Send($null);
    }
}

New-PolarisGetRoute -Path /dscnode -ScriptBlock {
    ipmo .\DSCPullServerAdmin.psm1
    if ($request.Query['name']) {
        $nodes = Get-DscPullServerRegistration -Name $request.Query['name'] -ConnectionString $env:ConnectionString
    } else {
        $nodes = Get-DscPullServerRegistration -ConnectionString $env:ConnectionString
    }
    if ($null -ne $nodes) {
        $response.Json(($nodes | ConvertTo-Json))
    } else {
        $response.Send($null);
    }
}

New-PolarisPutRoute -Path /dscnode -ScriptBlock {
    ipmo .\DSCPullServerAdmin.psm1
    if ($null -ne $request.Query['name'] -and $null -ne $request.Query['config']) {
        Set-DscPullServerNodeConfiguration -Name $request.Query['name'] -ConfigurationName $request.Query['config'] -ConnectionString $env:ConnectionString
    } else {
        throw 'name and config must be specified as part of the querystring ?name=node&config=mynewconfig'
    }
}

New-PolarisGetRoute -Path /dscconfiguration -ScriptBlock {
    $configurations = Get-ChildItem -Path c:\pullserver\configuration -Filter *.mof
    $configs = foreach ($c in $configurations) {
        [pscustomobject]@{
            Name = $c.BaseName
            Content = (cat $c.FullName -Encoding Unicode -Raw)
        }
    }
    if ($null -ne $configs) {
        $response.Json(($configs | ConvertTo-Json))
    } else {
        $response.Send($null);
    }
}

$null = Start-Polaris -Port 8080 -UseJsonBodyParserMiddleware

while ($true) {
    # will throw error when sql connection cannot be made
    try {
        $null = Get-DscPullServerRegistration -ConnectionString $env:ConnectionString
        Start-Sleep -Seconds 30
    } catch {
        throw 'Unable to communicate with the SQL Server'
    }
}
