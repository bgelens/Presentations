# SH-02
# we want to be able to scale in/out nodes through node configuration
Get-DscResource -Module xRemoteDesktopSessionHost

# we can use xRDServer but we need to be sure that the connectionbroker is already configured and up
# no resource to do that.

# WMF 5 WaitFor*
Get-DscResource -Module PSDesiredStateConfiguration -Name WaitFor*
<#
    WaitForAny  = 'in desired state on A specified node'
    WaitForSome = 'in desired state on a specified Amount of nodes'
    WaitForAll  = 'in desired state on ALL specified nodes'
#>

#region current config
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
#endregion

Get-DscResource -Module PSDesiredStateConfiguration -Name WaitForAny -Syntax

Invoke-DscResource -ModuleName PSDesiredStateConfiguration -Name WaitForAny -Method Test -Verbose -Property @{
    NodeName = [string[]]'cb-01'
    ResourceName = '[xRDSessionDeployment]Deployment'
}

# but whatif this node has changed config?

$pssession = New-PSSession -ComputerName cb-01
Invoke-Command -Session $pssession -ScriptBlock {
    Remove-DscConfigurationDocument -Stage Previous,Current,Pending
    Get-PSHostProcessInfo | ? AppDomainName -eq DscPsPluginWkr_AppDomain | kill -Force
}

# now try again
Invoke-DscResource -ModuleName PSDesiredStateConfiguration -Name WaitForAny -Method Test -Verbose -Property @{
    NodeName = [string[]]'cb-01'
    ResourceName = '[xRDSessionDeployment]Deployment'
}

# not functional test. If node has long lifecycle, it's expected that config document changes.
# E.g. [xRDSessionDeployment]Deployment becomes [RDSessionDeploymentDsc]Deployment

# let's create functional WaitFor resource for connectionbroker and collection