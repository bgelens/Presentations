#Create configuration and handle through LCM
configuration TestMyResource {
    Import-DscResource -ModuleName ExpertsLive
    DockerD MyDockerD {
        Ensure = 'Present'
        Path = 'C:\Program Files\Docker'
    }
}
TestMyResource
Start-DscConfiguration -Path .\TestMyResource -Wait -Verbose -Force