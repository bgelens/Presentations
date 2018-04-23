break

#region move to normal PS Host
if ($host.Name -eq 'Visual Studio Code Host') {
    Write-Warning -Message 'ctrl + shift + t'
}
Remove-Module -Name PSReadLine
#endregion

#region setup session
$passwordFile = Get-Content .\password.json | ConvertFrom-Json
$chost01Cred = [pscredential]::new($passwordFile.UserName, ($passwordFile.Password | ConvertTo-SecureString -AsPlainText -Force))
$session = New-PSSession -Credential $chost01Cred -ComputerName Chost01.mshome.net #-VMName CHost01
$session | Enter-PSSession
#endregion

#region install pull server
# windows feature already installed
Get-WindowsFeature -Name Dsc-Service

# xPSDSC already installed
Get-Module -ListAvailable -Name xPSDesiredStateConfiguration
Get-DscResource -Name xDscWebService
Get-DscResource -Name xDscWebService -Syntax

#implement localization fix (resource doesn't account for it yet)
New-Item `
    -ItemType SymbolicLink `
    -Path 'C:\Windows\System32\WindowsPowerShell\v1.0\modules\PSDesiredStateConfiguration\PullServer\en' `
    -Value 'C:\Windows\System32\WindowsPowerShell\v1.0\modules\PSDesiredStateConfiguration\PullServer\en-us'

Copy-Item `
    -Path 'C:\Windows\System32\WindowsPowerShell\v1.0\modules\PSDesiredStateConfiguration\PullServer\Microsoft.Powershell.DesiredStateConfiguration.Service.dll' `
    -Destination 'C:\Windows\System32\WindowsPowerShell\v1.0\modules\PSDesiredStateConfiguration\PullServer\en\Microsoft.Powershell.DesiredStateConfiguration.Service.Resources.dll'

# Show no DB yet in SSMS!

configuration PullServerSQL {

    Import-DscResource -ModuleName PSDesiredStateConfiguration -ModuleVersion 1.1
    Import-DscResource -ModuleName xPSDesiredStateConfiguration -ModuleVersion 8.1.0.0

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
        SqlConnectionString = "Provider=SQLNCLI11;Server=Chost02.mshome.net;Database=SQLDemo01;User ID=SA;Password=Welkom01;Initial Catalog=master;"
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

#region add pull client
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
#endregion

#region get / set node info via REST
# https://msdn.microsoft.com/en-us/library/dn393548.aspx
# [MS-DSCPM]: Desired State Configuration Pull Model Protocol

$uri = 'http://chost01.mshome.net:8080/PSDSCPullServer.svc{0}'
$irmArgs = @{
    Headers = @{
        Accept = 'application/json'
        ProtocolVersion = '2.0'
    }
    UseBasicParsing = $true
}
# available routes
(Invoke-RestMethod @irmArgs -Uri ($uri -f $null)).value

# Get single node
$agentId = (Get-DscLocalConfigurationManager).AgentId
$node = Invoke-RestMethod @irmArgs -Uri ($uri -f "/Nodes(AgentId = '$agentId')")
$node

# Update configurationname (basically re-registration)
$putArgs = @{
    Headers = @{
        Accept = 'application/json'
        ProtocolVersion = '2.0'
        Authorization = 'Basic {0}' -f [Convert]::ToBase64String([System.Text.Encoding]::Default.GetBytes('cb30127b-4b66-4f83-b207-c4801fb05087'))
    }
    UseBasicParsing = $true
}
$node.psobject.members.Remove('odata.metadata')
$node.ConfigurationNames = @('PSCONFEU')
$node.RegistrationInformation.RegistrationMessageType = 'ConfigurationRepository'
Invoke-RestMethod @putArgs -Uri ($uri -f "/Nodes(AgentId = '$agentId')") -Method Put -Body ($node | ConvertTo-Json) -ContentType 'application/json'

#check if it's updated
Invoke-RestMethod @irmArgs -Uri ($uri -f "/Nodes(AgentId = '$agentId')")

#reset to null
$node.ConfigurationNames = @()
Invoke-RestMethod @putArgs -Uri ($uri -f "/Nodes(AgentId = '$agentId')") -Method Put -Body ($node | ConvertTo-Json) -ContentType 'application/json'

# get reports
$reports = (Invoke-RestMethod @irmArgs -Uri ($uri -f "/Nodes(AgentId = '$agentId')/Reports")).value
$reports[0]
$reports[0].StatusData | ConvertFrom-Json

# multiple nodes
# not implemented AFAIK!
#endregion

#region get node data from database
$connectionString = "Server=Chost02.mshome.net;user id=sa;password=Welkom01;Database=SQLDemo01;Trusted_Connection=False"

$PSDefaultParameterValues = @{
    "*-DscPullServer*:ConnectionString" = $connectionString
}

function Get-DscPullServerRegistration {
    [cmdletbinding()]
    param (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Alias('NodeName')]
        [string] $Name,

        [Parameter(Mandatory)]
        [string] $ConnectionString
    )
    process {
        $connection = [System.Data.SqlClient.SqlConnection]::new($ConnectionString)
        $null = $connection.Open()
        $command = $connection.CreateCommand()
        if ($PSBoundParameters.ContainsKey('Name')) {
            if ($Name.ToCharArray() -contains '*') {
                $Name = $Name.Replace('*','%')
            }
            $command.CommandText = "SELECT * FROM RegistrationData Where NodeName like '{0}'" -f $Name
        } else {
            $command.CommandText = 'SELECT * FROM RegistrationData'
        }
        Write-Verbose -Message "Query: `n $($command.CommandText)"
        $results = $command.ExecuteReader()
        $returnArray = [System.Collections.ArrayList]::new()
        foreach ($result in $results) {
            $table = @{}
            for ($i = 0; $i -lt $result.FieldCount; $i++) {
                $name = $result.GetName($i)
                switch ($name) {
                    'ConfigurationNames' {
                        $data = ($result[$i] | ConvertFrom-Json)
                    }
                    'IPAddress' {
                        $data = $result[$i] -Split ','
                    }
                    default {
                        $data = $result[$i]
                    }
                }
                [void] $table.Add($name, $data)
            }
            $null = $returnArray.Add($table)
        }
        $returnArray.ForEach{[pscustomobject]$_}
        $connection.Close()
        $connection.Dispose()
    }
}
Get-DscPullServerRegistration
Get-DscPullServerRegistration -Name ch*st0* -Verbose
#endregion

#region get report data from database
function Get-DscPullServerReport {
    [cmdletbinding()]
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('NodeName')]
        [string] $Name,

        [Parameter()]
        [datetime] $StartTime,

        [Parameter(Mandatory)]
        [string] $ConnectionString
    )
    process {
        $connection = [System.Data.SqlClient.SqlConnection]::new($ConnectionString)
        $null = $connection.Open()
        $command = $connection.CreateCommand()
        if ($PSBoundParameters.ContainsKey('Name')) {
            if ($Name.ToCharArray() -contains '*') {
                $Name = $Name.Replace('*','%')
            }
            $query = "SELECT * FROM StatusReport Where NodeName like '{0}'" -f $Name
            if ($PSBoundParameters.ContainsKey('StartTime')) {
                $query += " and StartTime >= Convert(datetime, '{0}' )" -f $StartTime.ToString('yyyy-MM-dd HH:mm:ss')
            }
        } else {
            $query = 'SELECT * FROM StatusReport'
            if ($PSBoundParameters.ContainsKey('StartTime')) {
                $query += " Where StartTime >= Convert(datetime, '{0}' )" -f $StartTime.ToString('yyyy-MM-dd HH:mm:ss')
            }
        }
        $command.CommandText = $query
        Write-Verbose -Message "Query: `n $($command.CommandText)"
        $results = $command.ExecuteReader()
        $returnArray = [System.Collections.ArrayList]::new()
        foreach ($result in $results) {
            $table = @{}
            for ($i = 0; $i -lt $result.FieldCount; $i++) {
                $name = $result.GetName($i)
                switch ($name) {
                    { $_ -in 'StatusData', 'Errors'} {
                        $data = (($result[$i] | ConvertFrom-Json) | ConvertFrom-Json)
                    }
                    'AdditionalData' {
                        $data = ($result[$i] | ConvertFrom-Json)
                    }
                    'IPAddress' {
                        $data = $result[$i] -split ','
                    }
                    default {
                        $data = $result[$i]
                    }
                }
                [void] $table.Add($name, $data)
            }
            $null = $returnArray.Add($table)
        }
        $returnArray.ForEach{[pscustomobject]$_}
        $connection.Close()
        $connection.Dispose()
    }
}

Get-DscPullServerReport
Get-DscPullServerReport -Name CHOST01 -StartTime ([datetime]::now.AddMinutes(-15)) -Verbose
#endregion

#region create configuration
configuration MySuperServer {
    Import-DscResource -ModuleName PSDesiredStateConfiguration -ModuleVersion 1.1

    Node MySuperServer {
        File MySuperFile {
            Ensure = 'Present'
            DestinationPath = 'C:\Windows\Temp\MySuperFile.txt'
            Contents = 'PSCONFEU ROCKS!!!'
        }
    }
}
MySuperServer -OutputPath 'C:\Program Files\WindowsPowerShell\DscService\Configuration'
New-DscChecksum -Path 'C:\Program Files\WindowsPowerShell\DscService\Configuration\MySuperServer.mof'
#endregion

#region server side assignment
Get-DscPullServerRegistration -Name $env:COMPUTERNAME

function Set-DscPullServerNodeConfiguration {
    [cmdletbinding()]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('NodeName')]
        [string] $Name,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $ConfigurationName,

        [Parameter(Mandatory)]
        [string] $ConnectionString
    )
    process {
        $connection = [System.Data.SqlClient.SqlConnection]::new($ConnectionString)
        $null = $connection.Open()
        $command = $connection.CreateCommand()
        $query = "update RegistrationData set ConfigurationNames = '[ `"{0}`" ]' where NodeName = '{1}'" -f $ConfigurationName, $Name
        $command.CommandText = $query
        Write-Verbose -Message "Query: `n $($command.CommandText)"
        $command.ExecuteNonQuery()
        $connection.Close()
        $connection.Dispose()
    }
}

Get-DscPullServerRegistration -Name $env:COMPUTERNAME |
    Set-DscPullServerNodeConfiguration -ConfigurationName 'MySuperServer'

Get-DscPullServerRegistration -Name $env:COMPUTERNAME
Update-DscConfiguration -Wait -Verbose
Get-Content -Path 'C:\Windows\Temp\MySuperFile.txt'
Get-DscConfiguration
Get-DscConfigurationStatus
# local config still empty
(Get-DscLocalConfigurationManager).ConfigurationDownloadManagers
#endregion

# Go Back to slides!
