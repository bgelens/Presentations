#region setup session
$sqlsession | Enter-PSSession
#endregion

#region stop localsite
Stop-WebSite -Name PSDSCPullServer
Get-WebSite -Name PSDSCPullServer | Remove-WebSite
Get-WebSite
#endregion

#region container setup
docker version
docker images
#endregion

#region containerize
# build container images
# Image is prebaked to save time. Discuss Files!
Get-ChildItem -Path .\PullServerContainer
#docker build .\PullServerContainer -t bgelens/pullserver:latest --no-cache
docker images
#endregion

#region start pull server as container
docker run `
    -p 8080:8080 `
    -v C:\pullserver:C:\pullserver `
    -e ConnectionString="Provider=SQLOLEDB.1;Server=sql.mshome.net;Database=PSCONFASIADSC;User ID=SA;Password=Welkom01;" `
    --rm `
    -d bgelens/pullserver

docker ps
docker inspect (docker ps -q)

do {
    $logs = docker logs (docker ps -q)
} until ($null -ne $logs)
$logs

$uri = 'http://localhost:8080/PSDSCPullServer.svc{0}'
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

# see that update-dscconfig still works but now through container
Update-DscConfiguration -Wait -Verbose

# update node config for DSCClient
configuration MySuperServer {
    Import-DscResource -ModuleName PSDesiredStateConfiguration -ModuleVersion 1.1

    Node Awesome {
        File MySuperFile {
            Ensure = 'Present'
            DestinationPath = 'C:\Windows\Temp\MySuperFile.txt'
            Contents = 'PSCONFASIA 2018 on DOCKER and DSC ROCKS!!!'
        }
    }
}
MySuperServer -OutputPath 'C:\pullserver\Configuration'
New-DscChecksum -Path 'C:\pullserver\Configuration\Awesome.mof' -Force

Exit-PSSession

Invoke-Command -ScriptBlock {
    Update-DscConfiguration -Wait -Verbose
    Get-Content -Path C:\Windows\Temp\MySuperFile.txt
} -Session $lcmsession
#endregion
