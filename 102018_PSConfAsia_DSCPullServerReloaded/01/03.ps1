#region retarget lcm dscclient
$lcmsession | Enter-PSSession
(cat c:\windows\system32\drivers\etc\hosts) -match '^#' | Out-File c:\windows\system32\drivers\etc\hosts -Encoding ascii -Force
$sqlPullIP = (Resolve-DnsName -Name sqlpull.mshome.net -Type A)[0].IPAddress
"$sqlPullIP`tpullserver" | Out-File C:\Windows\System32\drivers\etc\hosts -Append -Encoding ascii
Resolve-DnsName -Name pullserver

Update-DscConfiguration -Wait -Verbose

Exit-PSSession
#endregion

#region copy configurations and db from old pull server
Copy-Item -FromSession $edbsession -Path 'C:\pullserver' -Destination . -Recurse
Copy-Item -ToSession $sqlsession -Path .\pullserver\Configuration\* -Destination c:\pullserver\Configuration\ -Recurse
#Copy-Item -ToSession $sqlsession -Path .\pullserver\Modules\* -Destination c:\pullserver\Modules\ -Recurse

$edbconnection = New-DSCPullServerAdminConnection -ESEFilePath .\pullserver\Devices.edb
$sqlconnection = New-DSCPullServerAdminConnection -SQLServer sql.mshome.net -Database PSCONFASIADSC -Credential sa

Copy-DSCPullServerAdminDataESEToSQL -ESEConnection $edbconnection -SQLConnection $sqlconnection -ObjectsToMigrate StatusReports, RegistrationData -WhatIf
Copy-DSCPullServerAdminDataESEToSQL -ESEConnection $edbconnection -SQLConnection $sqlconnection -ObjectsToMigrate StatusReports, RegistrationData -Force -Verbose

Get-DSCPullServerAdminRegistration -Connection $sqlconnection -NodeName dscclient
Get-DSCPullServerAdminStatusReport -Connection $sqlconnection -NodeName dscclient
#endregion

#region see if DSCCLient can now talk to sql pull server
Invoke-Command -Session $lcmsession -ScriptBlock {
    Update-DscConfiguration -Wait -Verbose
}
#endregion

#region server side configurationname assignment
$sqlsession | Enter-PSSession

configuration Awesome {
    Import-DscResource -ModuleName PSDesiredStateConfiguration -ModuleVersion 1.1

    Node Awesome {
        File MySuperFile {
            Ensure = 'Present'
            DestinationPath = 'C:\Windows\Temp\MySuperFile.txt'
            Contents = 'PSCONFASIA and DSC ROCKS!!!'
        }
    }
}
Awesome -OutputPath 'C:\pullserver\Configuration'
New-DscChecksum -Path 'C:\pullserver\Configuration\Awesome.mof' -Force

Exit-PSSession


Get-DSCPullServerAdminConnection
Set-DSCPullServerAdminConnectionActive -Connection $sqlConnection
Get-DSCPullServerAdminConnection

Get-DSCPullServerAdminRegistration -NodeName dscclient -Verbose

Get-DSCPullServerAdminRegistration -NodeName dscclient |
    Set-DSCPullServerAdminRegistration -ConfigurationNames 'Awesome'

Invoke-Command -Session $lcmsession -ScriptBlock {
    Update-DscConfiguration -Wait -Verbose
    cat C:\Windows\Temp\MySuperFile.txt
}
#endregion