#SH-02
#region update config
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
    Import-DscResource -ModuleName xRemoteDesktopSessionHost -ModuleVersion 1.0.1
    Import-DscResource -ModuleName PSConfEU

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
            CollectionName = $ConfigurationData.NonNodeData.CollectionName
            CollectionDescription = $ConfigurationData.NonNodeData.CollectionName
            SessionHosts = (
                $Allnodes.Where{$_.Role -eq 'RDSH' -and $_.IsFirstRDSH}.NodeName,
                $ConfigurationData.NonNodeData.DomainName -join '.'
            )
            PsDscRunAsCredential = $ConfigurationData.NonNodeData.DomainCred
            DependsOn = "[xRDSessionDeployment]Deployment"
        }
    }

    Node $Allnodes.Where{$_.Role -eq 'RDSH' -and -not $_.IsFirstRDSH}.NodeName {
        RDSWaitForRole CB {
            ConnectionBroker = (
                $Allnodes.Where{$_.Role -eq 'CB'}.NodeName,
                $ConfigurationData.NonNodeData.DomainName -join '.'
            )
            Role = 'RDS-CONNECTION-BROKER'
            PsDscRunAsCredential = $ConfigurationData.NonNodeData.DomainCred
        }

        xRDServer localnode {
            ConnectionBroker = (
                $Allnodes.Where{$_.Role -eq 'CB'}.NodeName,
                $ConfigurationData.NonNodeData.DomainName -join '.'
            )
            Role = 'RDS-RD-Server'
            Server = ($Node.NodeName, $ConfigurationData.NonNodeData.DomainName -join '.')
            PsDscRunAsCredential = $ConfigurationData.NonNodeData.DomainCred
            DependsOn = '[RDSWaitForRole]CB'
        }

        RDSWaitForCollection Collection {
            ConnectionBroker = (
                $Allnodes.Where{$_.Role -eq 'CB'}.NodeName,
                $ConfigurationData.NonNodeData.DomainName -join '.'
            )
            Name = $ConfigurationData.NonNodeData.CollectionName
            PsDscRunAsCredential = $ConfigurationData.NonNodeData.DomainCred
            DependsOn = '[xRDServer]localnode'
        }

        RDSCollectionMember CollectionMember {
            ConnectionBroker = (
                $Allnodes.Where{$_.Role -eq 'CB'}.NodeName,
                $ConfigurationData.NonNodeData.DomainName -join '.'
            )
            CollectionName = $ConfigurationData.NonNodeData.CollectionName
            Ensure = 'Present'
            PsDscRunAsCredential = $ConfigurationData.NonNodeData.DomainCred
            DependsOn = '[RDSWaitForCollection]Collection'
        }
    }
}
#endregion

Move-Item C:\windows\System32\Configuration\MetaConfig.mof.old C:\windows\System32\Configuration\MetaConfig.mof -Force
Move-Item C:\windows\System32\Configuration\MetaConfig.backup.mof.old C:\windows\System32\Configuration\MetaConfig.backup.mof -Force
Get-PSHostProcessInfo | ? AppDomainName -eq DscPsPluginWkr_AppDomain | kill -Force

RDSFarm -ConfigurationData $ConfigData
Get-ChildItem .\RDSFarm -Exclude SH-02.mof | Remove-Item
Start-DscConfiguration -Wait -Verbose .\RDSFarm -Force