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

#region stop localsite
Stop-WebSite -Name PSDSCPullServer
Get-WebSite -Name PSDSCPullServer | Remove-WebSite
Get-WebSite
#endregion

#region container setup
docker version
docker info
docker images
#endregion

#region containerize
New-Item -Name PullServerContainer -ItemType Directory
New-Item -Name Modules -ItemType Directory -Path .\PullServerContainer
Copy-Item -Path 'C:\Program Files\WindowsPowerShell\Modules\xPSDesiredStateConfiguration' -Destination .\PullServerContainer\Modules -Recurse -Force
Exit-PSSession

# first copy files

Copy-Item -ToSession $session -Path '.\02 - Docker\DockerFile' -Destination 'C:\Users\Administrator\Documents\PullServerContainer' -Force
Copy-Item -ToSession $session -Path '.\02 - Docker\Docker.ps1' -Destination 'C:\Users\Administrator\Documents\PullServerContainer' -Force
Copy-Item -ToSession $session -Path '.\02 - Docker\sqlncli.msi' -Destination 'C:\Users\Administrator\Documents\PullServerContainer' -Force
Copy-Item -ToSession $session -Path '.\02 - Docker\DockerMon.ps1' -Destination 'C:\Users\Administrator\Documents\PullServerContainer' -Force
$session | Enter-PSSession

# build container images
docker build .\PullServerContainer -t bgelens/pullserver:latest --no-cache
docker images

# during build, show files

New-Item -Path C:\pullserver -ItemType Directory
Copy-Item -Path 'C:\Program Files\WindowsPowerShell\DscService\*' -Recurse -Destination C:\pullserver
#endregion

#region start pull server as container
docker run `
    -p 8081:8080 `
    -v C:\pullserver:C:\pullserver `
    -e ConnectionString="Provider=SQLNCLI11;Server=CHost02.mshome.net;Database=SQLDemo01;User ID=SA;Password=Welkom01;Initial Catalog=master;" `
    --rm `
    -d bgelens/pullserver

docker ps
docker inspect (docker ps -q)

$uri = 'http://localhost:8081/PSDSCPullServer.svc{0}'
$irmArgs = @{
    Headers = @{
        Accept = 'application/json'
        ProtocolVersion = '2.0'
    }
    UseBasicParsing = $true
}
# see if service is listening
(Invoke-RestMethod @irmArgs -Uri ($uri -f $null)).value

# Get node
$agentId = (Get-DscLocalConfigurationManager).AgentId
Invoke-RestMethod @irmArgs -Uri ($uri -f "/Nodes(AgentId = '$agentId')")

# change LCM to see if we can make use of the container
[dsclocalconfigurationmanager()]
configuration lcm {
    Settings {
        RefreshMode = 'Pull'
    }

    ConfigurationRepositoryWeb SQLPullWeb {
        ServerURL = "http://$env:ComputerName`:8081/PSDSCPullServer.svc"
        RegistrationKey = 'cb30127b-4b66-4f83-b207-c4801fb05087'
        AllowUnsecureConnection = $true
        ConfigurationNames = 'MySuperServer'
    }

    ReportServerWeb SQLPullWeb {
        ServerURL = "http://$env:ComputerName`:8081/PSDSCPullServer.svc"
        RegistrationKey = 'cb30127b-4b66-4f83-b207-c4801fb05087'
        AllowUnsecureConnection = $true
    }
}
lcm
Set-DscLocalConfigurationManager .\lcm -Verbose

# update node config
configuration MySuperServer {
    Import-DscResource -ModuleName PSDesiredStateConfiguration -ModuleVersion 1.1

    Node MySuperServer {
        File MySuperFile {
            Ensure = 'Present'
            DestinationPath = 'C:\Windows\Temp\MySuperFile.txt'
            Contents = 'PSCONFEU 2018 on DOCKER and DSC ROCKS!!!'
        }
    }
}
MySuperServer -OutputPath 'C:\pullserver\Configuration'
New-DscChecksum -Path 'C:\pullserver\Configuration\MySuperServer.mof' -Force
Update-DscConfiguration -Wait -Verbose
Get-Content -Path C:\Windows\Temp\MySuperFile.txt
#endregion

#region scale
# run second container NOT THAT GREAT experience :)
docker run `
    -p 8082:8080 `
    -v C:\pullserver:C:\pullserver `
    -e ConnectionString="Provider=SQLNCLI11;Server=CHost01.mshome.net;Database=SQLDemo01;User ID=SA;Password=Welkom01;Initial Catalog=master;" `
    --rm `
    -d bgelens/pullserver

docker ps
docker ps -q | %{docker port $_}

docker rm -f (docker ps -aq)
#endregion

#region run as docker service [Requires Swarm Mode]
# can also be expressed in yaml
docker service create `
    --replicas 2 `
    --name DSCPullServer `
    -d `
    --publish 'published=8080,target=8080' `
    --mount 'type=bind,source=C:\pullserver,destination=C:\pullserver' `
    -e ConnectionString="Provider=SQLNCLI11;Server=CHost02.mshome.net;Database=SQLDemo01;User ID=SA;Password=Welkom01;Initial Catalog=master;" `
    bgelens/pullserver

docker service ls
$service = docker service inspect (docker service ls -q) | ConvertFrom-Json
$service
$service.endpoint.ports
docker ps

# note the AgentId
(Get-DscLocalConfigurationManager).AgentId

# from OUTSIDE host, multiple powershell windows
$agentId = '5B17A938-3F47-11E8-A549-00155D006904'
$uri = 'http://chost01.mshome.net:8080/PSDSCPullServer.svc{0}'
$irmArgs = @{
    Headers = @{
        Accept = 'application/json'
        ProtocolVersion = '2.0'
    }
    UseBasicParsing = $true
}

Invoke-RestMethod @irmArgs -Uri ($uri -f "/Nodes(AgentId = '$agentId')")
# show sql activity monitor!

# easy scale!
docker service scale DSCPullServer=3
docker service ls
docker ps
docker service scale DSCPullServer=1
# show still accessible from remote machine
#endregion

#region add new node
Exit-PSSession

[dsclocalconfigurationmanager()]
configuration lcm {
    Node LcmClient.mshome.net {
        Settings {
            RefreshMode = 'Pull'
        }

        ConfigurationRepositoryWeb SQLPullWeb {
            ServerURL = 'http://chost01.mshome.net:8080/PSDSCPullServer.svc'
            RegistrationKey = 'cb30127b-4b66-4f83-b207-c4801fb05087'
            AllowUnsecureConnection = $true
            ConfigurationNames = 'MySuperServer'
        }

        ReportServerWeb SQLPullWeb {
            ServerURL = 'http://chost01.mshome.net:8080/PSDSCPullServer.svc'
            RegistrationKey = 'cb30127b-4b66-4f83-b207-c4801fb05087'
            AllowUnsecureConnection = $true
        }
    }
}
lcm

$cimSession = New-CimSession -ComputerName Lcmclient.mshome.net -Credential $chost01Cred
Set-DscLocalConfigurationManager .\lcm -CimSession $cimSession -Verbose
Update-DscConfiguration -CimSession $cimSession -Verbose -Wait
Get-DscConfiguration -CimSession $cimSession

$session | Enter-PSSession
Get-DscPullServerRegistration
Get-DscPullServerReport -Name LCMClient | ft
#endregion
