# Same things but remotely
$nanoIp = '172.22.176.23'
Set-Item WSMan:\localhost\Client\TrustedHosts -Value $nanoIp -Force
$cred = [pscredential]::new('~\administrator',(ConvertTo-SecureString -String 'Welkom01' -AsPlainText -Force))
$cimsession = New-CimSession -ComputerName $nanoIp -Credential $cred
$pssession = New-PSSession -ComputerName $nanoIp -Credential $cred

[DscLocalConfigurationManager()]
configuration LCM {
    param (
        $Node   
    )
    node $Node {
        Settings {
            DebugMode = 'ForceModuleImport'
        }
    }
}
LCM -Node $nanoIp
Set-DscLocalConfigurationManager -Path .\LCM -Force -Verbose -CimSession $cimsession
Get-DscLocalConfigurationManager -CimSession $cimsession

Copy-Item -ToSession $pssession -Path ((Get-Module ExpertsLive -ListAvailable).Path | Split-Path -Parent) -Destination 'C:\Program Files\WindowsPowerShell\Modules' -Recurse -Container

#Create configuration and handle through LCM
configuration TestMyResource {
    param (
        $Node
    )
    Import-DscResource -ModuleName ExpertsLive
    node $Node {
        DockerD MyDockerD {
            Ensure = 'Present'
            Path = 'C:\Program Files\Docker'
        }
    }
}
TestMyResource -Node $nanoIp
Start-DscConfiguration -Path .\TestMyResource -Wait -Verbose -CimSession $cimsession

$pssession | Enter-PSSession
#fix resource (it's Nano :-) )
psedit (Get-ChildItem -Path (Get-DscResource -Module ExpertsLive).ParentPath -Filter *.psm1).fullname
Exit-PSSession

Start-DscConfiguration -UseExisting -CimSession $cimsession -Wait -Verbose

# Update psm1 with Code text file
$pssession | Enter-PSSession
psedit (Get-ChildItem -Path (Get-DscResource -Module ExpertsLive).ParentPath -Filter *.psm1).fullname
#copy
Exit-PSSession

#update config
configuration TestMyResource {
    param (
        $Node
    )
    Import-DscResource -ModuleName ExpertsLive
    node $Node {

        Environment DockerEnv {
            Path = $true
            Name = 'Path'
            Value = 'C:\Program Files\docker\'
        }

        DockerD DockerService {
            Ensure = 'Present'
            Path = 'C:\Program Files\docker\'
        }

        service DockerD {
            Name = 'Docker'
            State = 'Running'
            StartupType = 'Automatic'
            DependsOn = '[DockerD]DockerService'
        }
    }
}

TestMyResource -Node $nanoIp
Start-DscConfiguration -Path .\TestMyResource -Wait -Verbose -CimSession $cimsession #should fail! TODO: Introduce bugs in code
