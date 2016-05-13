# Same things but remotely
Set-Item WSMan:\localhost\Client\TrustedHosts -Value 10.10.10.2 -Force
$cred = [pscredential]::new('~\administrator',(ConvertTo-SecureString -String 'Welkom01' -AsPlainText -Force))
$cimsession = New-CimSession -ComputerName 10.10.10.2 -Credential $cred
$pssession = New-PSSession -ComputerName 10.10.10.2 -Credential $cred

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
LCM -Node 10.10.10.2
Set-DscLocalConfigurationManager -Path .\LCM -Force -Verbose -CimSession $cimsession
Get-DscLocalConfigurationManager -CimSession $cimsession

Copy-Item -ToSession $pssession -Path ((Get-Module PSConfEU -ListAvailable).Path | Split-Path -Parent) -Destination 'C:\Program Files\WindowsPowerShell\Modules' -Recurse -Container

#Create configuration and handle through LCM
configuration TestMyResource {
    param (
        $Node
    )
    Import-DscResource -ModuleName PSConfEU
    node $Node {
        SMBShare MyShare {
            Ensure = 'Present'
            Path = 'c:\myshare'
            Name = 'MyShare'
        }
    }
}
TestMyResource -Node 10.10.10.2
Start-DscConfiguration -Path .\TestMyResource -Wait -Verbose -CimSession $cimsession

$pssession | Enter-PSSession
#fix resource (it's Nano :-) )
psedit (Get-ChildItem -Path (Get-DscResource -Module PSConfEU).ParentPath -Filter *.psm1).fullname
Exit-PSSession

Start-DscConfiguration -UseExisting -CimSession $cimsession -Wait -Verbose

# Update psm1 with demo06 content
$pssession | Enter-PSSession
psedit (Get-ChildItem -Path (Get-DscResource -Module PSConfEU).ParentPath -Filter *.psm1).fullname
#copy
Exit-PSSession

#update config
configuration TestMyResource {
    param (
        $Node
    )
    Import-DscResource -ModuleName PSConfEU
    node $Node {
        file MyShareDir {
            Ensure = 'Present'
            DestinationPath = 'c:\myshare'
            Type = 'Directory'
        }

        SMBShare MyShare {
            Ensure = 'Present'
            Path = 'c:\myshare'
            Name = 'MyShare'
            FullAccess = 'Administrators'
            DependsOn = '[File]MyShareDir'
        }
    }
}
TestMyResource -Node 10.10.10.2
Start-DscConfiguration -Path .\TestMyResource -Wait -Verbose -CimSession $cimsession