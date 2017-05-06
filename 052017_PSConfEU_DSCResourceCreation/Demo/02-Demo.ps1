# CB-01
# to start RDS deployment, 1 session host is always required to kickstart
# this session host is never evaluated by test though so scaling can/must happen using other means
psedit (Get-DscResource -Module xRemoteDesktopSessionHost -Name xRDSessionDeployment).Path

#region current config
$ConfigData = @{
    AllNodes = @(
        @{
            NodeName = 'DC-01'
            Role = 'PDC'
            IPAddress = '172.22.176.60'
        },
        @{
            NodeName = 'CB-01'
            Role = 'CB'
        },
        @{
            NodeName = 'SH-01'
            Role = 'RDSH'
            IsFirstRDSH = $true
        }
        @{
            NodeName = 'SH-02'
            Role = 'RDSH'
        },
        @{
            NodeName = '*'
            PSDscAllowPlainTextPassword = $true
            PSDscAllowDomainUser = $true
        }
    )
    NonNodeData = @{
        DomainName = 'psconf.eu'
        DomainCred = [pscredential]::new('PSConfEU\Administrator',(ConvertTo-SecureString 'Welkom01' -AsPlainText -Force))
        CollectionName = 'PSConfEU'
    }
}

configuration RDSFarm {
    Import-DscResource -ModuleName PSDesiredStateConfiguration -ModuleVersion 1.1
    Import-DscResource -ModuleName xComputerManagement
    Import-DscResource -ModuleName xNetworking
    Import-DscResource -ModuleName xActiveDirectory

    Node $Allnodes.Where{$_.Role -eq 'RDSH'}.NodeName {
        WindowsFeature Remote-Desktop-Services {
            Ensure = "Present"
            Name = "Remote-Desktop-Services"
        }

        WindowsFeature RDS-RD-Server {
            Ensure = "Present"
            Name = "RDS-RD-Server"
        }

        WindowsFeature RSAT-RDS-Tools {
            Ensure = "Present"
            Name = "RSAT-RDS-Tools"
            IncludeAllSubFeature = $true
        }
    }

    Node $Allnodes.Where{$_.Role -ne 'PDC'}.NodeName {
        xDNSServerAddress DCDNS {
            InterfaceAlias = 'Ethernet'
            Address = $Allnodes.Where{$_.Role -eq 'PDC'}.IPAddress
            AddressFamily = 'IPv4'
            Validate = $false
        }

        xWaitForADDomain DscForestWait {
            DomainName = $ConfigurationData.NonNodeData.DomainName
            DomainUserCredential = $ConfigurationData.NonNodeData.DomainCred
        }

        xComputer Rename {
            Name =  $Node.NodeName
            DomainName = $ConfigurationData.NonNodeData.DomainName
            Credential = $ConfigurationData.NonNodeData.DomainCred
            DependsOn = '[xWaitForADDomain]DscForestWait'
        }
    }

    Node $Allnodes.Where{$_.Role -eq 'CB'}.NodeName {
        WindowsFeature RDSConnectionBroker {
            Ensure = 'Present'
            Name = 'RDS-Connection-Broker'
        }
    }

    Node $Allnodes.Where{$_.Role -eq 'RDSH' -and -not $_.IsFirstRDSH}.NodeName {

    }
}
#endregion

#region update config with RDS deployment and collection
configuration RDSFarm {
    Import-DscResource -ModuleName PSDesiredStateConfiguration -ModuleVersion 1.1
    Import-DscResource -ModuleName xComputerManagement
    Import-DscResource -ModuleName xNetworking
    Import-DscResource -ModuleName xActiveDirectory
    Import-DscResource -ModuleName xRemoteDesktopSessionHost -ModuleVersion 1.0.1

    Node $Allnodes.Where{$_.Role -eq 'RDSH'}.NodeName {
        WindowsFeature Remote-Desktop-Services {
            Ensure = "Present"
            Name = "Remote-Desktop-Services"
        }

        WindowsFeature RDS-RD-Server {
            Ensure = "Present"
            Name = "RDS-RD-Server"
        }

        WindowsFeature RSAT-RDS-Tools {
            Ensure = "Present"
            Name = "RSAT-RDS-Tools"
            IncludeAllSubFeature = $true
        }
    }

    Node $Allnodes.Where{$_.Role -ne 'PDC'}.NodeName {
        xDNSServerAddress DCDNS {
            InterfaceAlias = 'Ethernet'
            Address = $Allnodes.Where{$_.Role -eq 'PDC'}.IPAddress
            AddressFamily = 'IPv4'
            Validate = $false
        }

        xWaitForADDomain DscForestWait {
            DomainName = $ConfigurationData.NonNodeData.DomainName
            DomainUserCredential = $ConfigurationData.NonNodeData.DomainCred
        }

        xComputer Rename {
            Name =  $Node.NodeName
            DomainName = $ConfigurationData.NonNodeData.DomainName
            Credential = $ConfigurationData.NonNodeData.DomainCred
            DependsOn = '[xWaitForADDomain]DscForestWait'
        }
    }

    Node $Allnodes.Where{$_.Role -eq 'CB'}.NodeName {
        WindowsFeature RDSConnectionBroker {
            Ensure = 'Present'
            Name = 'RDS-Connection-Broker'
        }

        xRDSessionDeployment Deployment {
            ConnectionBroker = (
                $Node.NodeName,
                $ConfigurationData.NonNodeData.DomainName -join '.'
            )
            SessionHosts = (
                $Allnodes.Where{$_.Role -eq 'RDSH' -and $_.IsFirstRDSH}.NodeName,
                $ConfigurationData.NonNodeData.DomainName -join '.'
            )
            PsDscRunAsCredential = $ConfigurationData.NonNodeData.DomainCred
            DependsOn = '[WindowsFeature]RDSConnectionBroker'
        }

        xRDSessionCollection Collection {
            ConnectionBroker = (
                $Node.NodeName,
                $ConfigurationData.NonNodeData.DomainName -join '.'
            )
            CollectionName = 'PSConfEU'
            CollectionDescription = 'PSConfEU'
            SessionHosts = (
                $Allnodes.Where{$_.Role -eq 'RDSH' -and $_.IsFirstRDSH}.NodeName,
                $ConfigurationData.NonNodeData.DomainName -join '.'
            )
            PsDscRunAsCredential = $ConfigurationData.NonNodeData.DomainCred
            DependsOn = "[xRDSessionDeployment]Deployment"
        }
    }

    Node $Allnodes.Where{$_.Role -eq 'RDSH' -and -not $_.IsFirstRDSH}.NodeName {
        
    }
}

RDSFarm -ConfigurationData $ConfigData
Remove-Item .\RDSFarm\SH-0?.mof
Start-DscConfiguration -Wait -Verbose -Path .\RDSFarm -Force
#endregion

#region update server manager
$SRVManagerXML = [xml](Get-Content C:\Users\administrator.psconfeu\AppData\Roaming\Microsoft\Windows\ServerManager\ServerList.xml)
'sh-01','sh-02' | ForEach-Object -Process {
    $newserver = @($SRVManagerXML.ServerList.ServerInfo)[0].clone()
    $newserver.name = ('{0}.psconf.eu' -f $_)
    $newserver.lastUpdateTime = '0001-01-01T00:00:00'
    $newserver.status = '2'
    [void]$SRVManagerXML.ServerList.AppendChild($newserver)
}
$SRVManagerXML.Save('C:\Users\administrator.psconfeu\AppData\Roaming\Microsoft\Windows\ServerManager\ServerList.xml')
Start-Process -FilePath ServerManager.exe
#endregion
