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

#region add admin "micro" service
New-Item -Name PullServerAdminContainer -ItemType Directory
Exit-PSSession

# copy in files
Copy-Item -ToSession $session -Path '.\03 - Polaris\Polaris' -Destination 'C:\Users\Administrator\Documents\PullServerAdminContainer' -Recurse -Force
Copy-Item -ToSession $session -Path '.\03 - Polaris\adminservice.ps1' -Destination 'C:\Users\Administrator\Documents\PullServerAdminContainer' -Force
Copy-Item -ToSession $session -Path '.\03 - Polaris\DSCPullServerAdmin.psm1' -Destination 'C:\Users\Administrator\Documents\PullServerAdminContainer' -Force
Copy-Item -ToSession $session -Path '.\03 - Polaris\DockerFile' -Destination 'C:\Users\Administrator\Documents\PullServerAdminContainer' -Force
$session | Enter-PSSession

docker build .\PullServerAdminContainer -t bgelens/pullserveradmin:latest --no-cache
# During build, look at files

docker images

# create admin service
docker service create `
    --replicas 1 `
    --name DSCPullServerAdmin `
    -d `
    --publish 'published=8081,target=8080' `
    --mount 'type=bind,source=C:\pullserver,destination=C:\pullserver' `
    -e ConnectionString="Server=chost02.mshome.net;user id=sa;password=Welkom01;Database=SQLDemo01;Trusted_Connection=False" `
    bgelens/pullserveradmin

docker service ls
docker ps
#endregion

#region query admin service
Exit-PSSession

irm -UseBasicParsing -Uri http://chost01.mshome.net:8081/dscnode
irm -UseBasicParsing -Uri 'http://chost01.mshome.net:8081/dscnode?name=chost01&config=EverythingIsAwesome' -Method Put
irm -UseBasicParsing -Uri http://chost01.mshome.net:8081/dscnode?name=chost01
irm -UseBasicParsing -Uri http://chost01.mshome.net:8081/dscreport
irm -UseBasicParsing -Uri http://chost01.mshome.net:8081/dscconfiguration | fl
#endregion

#region what else?
# Authentication
# Add / Get Modules
# Add configurations
# layer admin dashboard
# more filtering options
# on demand compile
# pull server as a service
# extend LCM downloadmanager and have cert exchange, lcm settings
# you tell me :)
#endregion
