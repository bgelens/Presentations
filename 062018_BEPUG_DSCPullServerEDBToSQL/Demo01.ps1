break

#region move to normal PS Host
if ($host.Name -eq 'Visual Studio Code Host') {
    Write-Warning -Message 'ctrl + shift + t'
}
Remove-Module -Name PSReadLine
#endregion

#region setup edb pull session
$passwordFile = Get-Content .\password.json | ConvertFrom-Json
$chostCred = [pscredential]::new($passwordFile.UserName, ($passwordFile.Password | ConvertTo-SecureString -AsPlainText -Force))
$edbsession = New-PSSession -Credential $chostCred -ComputerName Chost04.mshome.net
$edbsession | Enter-PSSession
#endregion

#region edb pull server already installed
Get-WindowsFeature -Name Dsc-Service
Get-Website
([xml](Get-Content -Path C:\inetpub\PSDSCPullServer\web.config)).configuration.appsettings.GetEnumerator()

#create config for new client
configuration MySuperServer {
    Import-DscResource -ModuleName PSDesiredStateConfiguration -ModuleVersion 1.1

    Node MySuperServer {
        File MySuperFile {
            Ensure = 'Present'
            DestinationPath = 'C:\Windows\Temp\MySuperFile.txt'
            Contents = 'BEPUG ROCKS!!!'
        }
    }
}
MySuperServer -OutputPath 'C:\Program Files\WindowsPowerShell\DscService\Configuration'
New-DscChecksum -Path 'C:\Program Files\WindowsPowerShell\DscService\Configuration\MySuperServer.mof'

Exit-PSSession
#endregion

#region add pull client
$lcmsession = New-PSSession -Credential $chostCred -ComputerName lcmclient.mshome.net
$lcmsession | Enter-PSSession

Get-DscLocalConfigurationManager

cat C:\Windows\System32\drivers\etc\hosts
$edbPullIP = (Resolve-DnsName -Name chost04.mshome.net).IPAddress
"$edbPullIP`tpullserver" | Out-File C:\Windows\System32\drivers\etc\hosts -Append -Encoding ascii
Resolve-DnsName -Name pullserver

[dsclocalconfigurationmanager()]
configuration lcm {
    Settings {
        RefreshMode = 'Pull'
    }

    ConfigurationRepositoryWeb SQLPullWeb {
        ServerURL = 'http://pullserver:8080/PSDSCPullServer.svc'
        RegistrationKey = 'cb30127b-4b66-4f83-b207-c4801fb05087'
        AllowUnsecureConnection = $true
        ConfigurationNames = 'MySuperServer'
    }

    ReportServerWeb SQLPullWeb {
        ServerURL = 'http://pullserver:8080/PSDSCPullServer.svc'
        RegistrationKey = 'cb30127b-4b66-4f83-b207-c4801fb05087'
        AllowUnsecureConnection = $true
    }
}
lcm
Set-DscLocalConfigurationManager .\lcm -Verbose

Update-DscConfiguration -Wait -Verbose
cat C:\Windows\Temp\MySuperFile.txt
Exit-PSSession
#endregion

#region discontinue edb pullserver
Invoke-Command -Session $edbsession -ScriptBlock {
    #Get-Website -Name PSDSCPullServer | Stop-Website -Passthru
    iisreset /stop
}
#endregion

#region setup sql pullserver
$sqlsession = New-PSSession -Credential $chostCred -ComputerName chost03.mshome.net
$sqlsession | Enter-PSSession

[environment]::osversion

# not installed yet
Get-WebSite

# a lot already installed to save time
# windows feature already installed
Get-WindowsFeature -Name Dsc-Service

# xPSDSC already installed
Get-Module -ListAvailable -Name xPSDesiredStateConfiguration
Get-DscResource -Name xDscWebService -Syntax

# sql client already installed
Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server Native Client 11.0'

# setup pull server
configuration PullServerSQL {

    Import-DscResource -ModuleName PSDesiredStateConfiguration -ModuleVersion 1.1
    Import-DscResource -ModuleName xPSDesiredStateConfiguration -ModuleVersion 8.2.0.0

    xDscWebService PSDSCPullServer {
        Ensure                  = 'Present'
        EndpointName            = 'PSDSCPullServer'
        Port                    = 8080
        PhysicalPath            = "$env:SystemDrive\inetpub\PSDSCPullServer"
        CertificateThumbPrint   = 'AllowUnencryptedTraffic'
        ModulePath              = "$env:PROGRAMFILES\WindowsPowerShell\DscService\Modules"
        ConfigurationPath       = "$env:PROGRAMFILES\WindowsPowerShell\DscService\Configuration"
        State                   = 'Started'
        RegistrationKeyPath     = "$env:PROGRAMFILES\WindowsPowerShell\DscService"
        AcceptSelfSignedCertificates = $true
        UseSecurityBestPractices = $false
        SqlProvider = $true
        SqlConnectionString = "Provider=SQLNCLI11;Server=Chost02.mshome.net;Database=BEPUGDSC;User ID=SA;Password=Welkom01;Initial Catalog=master;"
    }

    File RegistrationKeyFile {
        Ensure = 'Present'
        Type = 'File'
        DestinationPath = "$env:ProgramFiles\WindowsPowerShell\DscService\RegistrationKeys.txt"
        Contents = 'cb30127b-4b66-4f83-b207-c4801fb05087'
    }
}

PullServerSQL
Start-DscConfiguration -Path .\PullServerSQL -Wait -Verbose -Force
([xml](Get-Content -Path C:\inetpub\PSDSCPullServer\web.config)).configuration.appsettings.GetEnumerator()
#endregion

#region add pull client will create db
[dsclocalconfigurationmanager()]
configuration lcm {
    Settings {
        RefreshMode = 'Pull'
    }

    ConfigurationRepositoryWeb SQLPullWeb {
        ServerURL = "http://$env:ComputerName`:8080/PSDSCPullServer.svc"
        RegistrationKey = 'cb30127b-4b66-4f83-b207-c4801fb05087'
        AllowUnsecureConnection = $true
    }

    ReportServerWeb SQLPullWeb {
        ServerURL = "http://$env:ComputerName`:8080/PSDSCPullServer.svc"
        RegistrationKey = 'cb30127b-4b66-4f83-b207-c4801fb05087'
        AllowUnsecureConnection = $true
    }
}
lcm
Set-DscLocalConfigurationManager .\lcm -Verbose
# show data in table via SSMS
Exit-PSSession
#endregion

#region copy configurations from old pull server
$configPath = 'C:\Program Files\WindowsPowerShell\DscService\Configuration'
Copy-Item -FromSession $edbsession -Path $configPath -Destination . -Recurse
Copy-Item -ToSession $sqlsession -Path .\Configuration\* -Destination $configPath -Recurse
#endregion

#region have lcm client try to pull from sql pullserver
$lcmsession | Enter-PSSession
(cat c:\windows\system32\drivers\etc\hosts) -match '^#' | Out-File c:\windows\system32\drivers\etc\hosts -Encoding ascii -Force
$sqlPullIP = (Resolve-DnsName -Name chost03.mshome.net).IPAddress
"$sqlPullIP`tpullserver" | Out-File C:\Windows\System32\drivers\etc\hosts -Append -Encoding ascii
Resolve-DnsName -Name pullserver

Update-DscConfiguration -Wait -Verbose
Exit-PSSession
#endregion

#region migrate data
Copy-Item -FromSession $edbsession -Path 'C:\Program Files\WindowsPowerShell\DscService\' -Destination . -Recurse
Copy-Item -ToSession $sqlsession -Path .\DscService -Destination c:\ -Recurse

$sqlSession | Enter-PSSession

# dscpull server admin module already installed
Get-Module -Name DscPullServerAdmin -ListAvailable
Get-Command -Module DscPullServerAdmin

# setup edb connection
$eseConnection = New-DSCPullServerAdminConnection -ESEFilePath C:\DscService\Devices.edb
$eseConnection
Get-DSCPullServerAdminRegistration
Get-DSCPullServerAdminStatusReport

# setup sql connection
$newConnectionArgs = @{
    SQLServer = 'Chost02.mshome.net'
    Credential = [pscredential]::new('sa', (convertto-securestring 'Welkom01' -asplaintext -force))
    Database = 'BEPUGDSC'
}

$sqlConnection = New-DSCPullServerAdminConnection @newConnectionArgs
Get-DSCPullServerAdminRegistration -Connection $sqlConnection

Copy-DSCPullServerAdminDataESEToSQL -ESEConnection $eseConnection -SQLConnection $sqlConnection -ObjectsToMigrate RegistrationData -WhatIf
Copy-DSCPullServerAdminDataESEToSQL -ESEConnection $eseConnection -SQLConnection $sqlConnection -ObjectsToMigrate RegistrationData

Get-DSCPullServerAdminRegistration -Connection $sqlConnection

Exit-PSSession
#endregion

#region lcm client retry
Invoke-Command -Session $lcmsession -ScriptBlock {
    Update-DscConfiguration -Wait -Verbose
}
#endregion

#region update configuration
$sqlsession | Enter-PSSession

configuration Awesome {
    Import-DscResource -ModuleName PSDesiredStateConfiguration -ModuleVersion 1.1

    Node Awesome {
        File MySuperFile {
            Ensure = 'Present'
            DestinationPath = 'C:\Windows\Temp\MySuperFile.txt'
            Contents = 'BEPUG and DSC ROCKS!!!'
        }
    }
}
Awesome -OutputPath 'C:\Program Files\WindowsPowerShell\DscService\Configuration'
New-DscChecksum -Path 'C:\Program Files\WindowsPowerShell\DscService\Configuration\Awesome.mof' -Force

Set-DSCPullServerAdminConnectionActive -Connection $sqlConnection
Get-DSCPullServerAdminConnection

Get-DSCPullServerAdminRegistration -NodeName lcmclient -Verbose

Get-DSCPullServerAdminRegistration -NodeName lcmclient |
    Set-DSCPullServerAdminRegistration -ConfigurationNames 'Awesome'

Exit-PSSession

Invoke-Command -Session $lcmsession -ScriptBlock {
    Update-DscConfiguration -Wait -Verbose
    cat C:\Windows\Temp\MySuperFile.txt
}
#endregion
