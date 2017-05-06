# DSC pull Server can be setup either as HTTP or HTTPS endpoint
# The xPSDesiredStateConfiguration module can be used to setup the pull server in a declarative way
# Install the module
Install-Module -Name xPSDesiredStateConfiguration -Force

# Get the resource names from xPSDesiredStateConfiguration module
Get-DscResource -Module xPSDesiredStateConfiguration

# We use the xDSCWebService resource to setup a pull server
# For the demo purpose, we will setup a HTTP web service
configuration DscPullServer
{ 
    param  
    ( 
        [ValidateNotNullOrEmpty()] 
        [string] $certificateThumbPrint,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $RegistrationKey 
    )

    Import-DSCResource -ModuleName xPSDesiredStateConfiguration
    Import-DSCResource –ModuleName PSDesiredStateConfiguration

    WindowsFeature DSCServiceFeature 
    { 
        Ensure = 'Present'
        Name   = 'DSC-Service'             
    } 

    xDscWebService PSDSCPullServer 
    { 
        Ensure                   = 'Present' 
        EndpointName             = 'PSDSCPullServer' 
        Port                     = 8080 
        PhysicalPath             = "$env:SystemDrive\inetpub\PSDSCPullServer" 
        CertificateThumbPrint    = $certificateThumbPrint          
        ModulePath               = "$env:PROGRAMFILES\WindowsPowerShell\DscService\Modules" 
        ConfigurationPath        = "$env:PROGRAMFILES\WindowsPowerShell\DscService\Configuration" 
        State                    = 'Started'
        DependsOn                = '[WindowsFeature]DSCServiceFeature'     
        UseSecurityBestPractices = $false
    } 

    File RegistrationKeyFile
    {
        Ensure          = 'Present'
        Type            = 'File'
        DestinationPath = "$env:ProgramFiles\WindowsPowerShell\DscService\RegistrationKeys.txt"
        Contents        = $RegistrationKey
    }
}

# For http based pull service, we will pass AllowUnencryptedTraffic as the argument to CertificateThumbprint
DSCPullServer -certificateThumbprint 'AllowUnencryptedTraffic' -RegistrationKey '140a952b-b9d6-406b-b416-e0f759c9c0e4' -OutputPath C:\DemoScripts\PullServer

# Run the compiled configuration to make the target node a DSC Pull Server
Start-DscConfiguration -Path C:\DemoScripts\PullServer -Wait -Verbose -Force

# Access the DSC pull endpoint in browser
Start-Process -FilePath 'http://localhost:8080/PSDSCPullServer.svc'

(irm 'http://localhost:8080/PSDSCPullServer.svc' -Headers @{Accept='application/json'}).value

# explore what is created
Import-Module WebAdministration
Get-Website -Name PSDSCPullServer | select *
Get-ChildItem C:\inetpub\PSDSCPullServer
$Configuration = [xml](Get-Content C:\inetpub\PSDSCPullServer\web.config)
$Configuration.configuration.appSettings.GetEnumerator()

# We can now onboard a DSC Pull client
[DSCLocalConfigurationManager()]
configuration PullClientConfig
{
    Node S12R2-01
    {
        Settings
        {
            RefreshMode          = 'Pull'
            RefreshFrequencyMins = 30 
            RebootNodeIfNeeded   = $true
        }

        ConfigurationRepositoryWeb PSConfEU-PullSrv
        {
            ServerURL          = 'http://S16-DC:8080/PSDSCPullServer.svc'
            RegistrationKey    = '140a952b-b9d6-406b-b416-e0f759c9c0e4'
            AllowUnsecureConnection = $true
            ConfigurationNames = @('ArchiveDemo')
        }   

        ReportServerWeb PSConfEU-PullSrv
        {
            ServerURL       = 'http://S16-DC:8080/PSDSCPullServer.svc'
            RegistrationKey = '140a952b-b9d6-406b-b416-e0f759c9c0e4'
            AllowUnsecureConnection = $true
        }
    }
}

PullClientConfig -OutputPath c:\DemoScripts\PullClientConfig
Set-DscLocalConfigurationManager -Path c:\DemoScripts\PullClientConfig -ComputerName S12R2-01 -Verbose

# explore registration
function GetReport
{
    param(
        $AgentId,
        $serviceURL = "http://localhost:8080/PSDSCPullServer.svc"
    )
    $requestUri = "$serviceURL/Nodes(AgentId= '$AgentId')/Reports"
    $request = Invoke-WebRequest -Uri $requestUri  -ContentType "application/json;odata=minimalmetadata;streaming=true;charset=utf-8" `
               -UseBasicParsing -Headers @{Accept = "application/json";ProtocolVersion = "2.0"} `
               -ErrorAction SilentlyContinue -ErrorVariable ev
    $object = ConvertFrom-Json $request.content
    return $object.value
}
GetReport -AgentId (Get-DscLocalConfigurationManager -CimSession s12r2-01).AgentId

Install-Module DSCPullServerAdmin -Force
Get-Command -Module DSCPullServerAdmin
Stop-Website -Name PSDSCPullServer
Stop-WebAppPool -Name PSWS
Mount-DSCPullServerAdminDatabase -ESEPath "$env:PROGRAMFILES\WindowsPowerShell\DscService\Devices.edb"
# v1
Get-DSCPullServerAdminDevice
# v2
Get-DSCPullServerAdminRegistration
Get-DSCPullServerAdminReport -NodeName S12R2-01

Dismount-DSCPullServerAdminDataBase

Start-WebAppPool -Name PSWS
Start-Website -Name PSDSCPullServer

# Before the LCM client can pull the configuration, ArchiveDemo in this example, the configuration and any required modules should be available on the pull server.
# for configuration, the naming convention should be <ConfigurationName>.mof. 
# This configurationname should match what is listed in the configurationnames property of the LCM client configuration
configuration ArchiveDemo
{
    Import-DscResource -modulename PSDesiredStateConfiguration
    Import-DscResource -ModuleName xNetworking -ModuleVersion 3.2.0.0

    Archive ArchiveResource
    {
        Path = 'C:\DemoScripts\scripts.zip'
        Destination = 'C:\Scripts'
        Ensure = 'Present'
    }

    xHostsFile HostEntry
    {
        IPAddress = '101.09.01.10'
        HostName = 'TESTHOST100'
    }
}

# Compile
ArchiveDemo -OutputPath C:\DemoScripts\ArchiveDemoForPull

# rename the MOF to reflect configuration name
Rename-Item -Path C:\DemoScripts\ArchiveDemoForPull\localhost.mof -NewName C:\DemoScripts\ArchiveDemoForPull\ArchiveDemo.mof

# Create a checksum for this. This is needed for the pull client to understand if there are subsequent changes to the configuration
New-DscChecksum -Path C:\DemoScripts\ArchiveDemoForPull\ArchiveDemo.mof -OutPath C:\DemoScripts\ArchiveDemoForPull

# move to configuration repository
Move-Item -Path C:\DemoScripts\ArchiveDemoForPull\* -Destination "$env:PROGRAMFILES\WindowsPowerShell\DscService\Configuration"

# update the config and show it fails
Update-DscConfiguration -ComputerName S12R2-01 -Wait -Verbose

# Package custom module as a zip archive. This is not required if configuration contains only in-box resources
# Before packaging up for the pull server simply remove the {Module version} folder so the path becomes '{Module Folder}\DscResources{DSC Resource Folder}\'.
# With this change, zip the folder as described above and place these zip files in the ModulePath folder.
# Copy the module zip to Pull Server.
$xNetworkingModule = Get-Module -Name xNetworking -ListAvailable
Compress-Archive -Path "$($xNetworkingModule.ModuleBase)\*" -DestinationPath "$env:PROGRAMFILES\WindowsPowerShell\DscService\Modules\xNetworking_$($xNetworkingModule.Version).zip" -Verbose

# inspect result
Get-ChildItem "$env:PROGRAMFILES\WindowsPowerShell\DscService\Modules"
[io.compression.zipfile]::OpenRead("$env:PROGRAMFILES\WindowsPowerShell\DscService\Modules\xNetworking_$($xNetworkingModule.Version).zip").Entries.FullName

# update the LCM client so that it downloads the configuration and modules
Update-DscConfiguration -ComputerName S12R2-01 -Wait -Verbose

# add checksum and try again :)
New-DscChecksum -Path "$env:PROGRAMFILES\WindowsPowerShell\DscService\Modules"
Get-ChildItem "$env:PROGRAMFILES\WindowsPowerShell\DscService\Modules"
Update-DscConfiguration -ComputerName S12R2-01 -Wait -Verbose
