$GUID = [guid]::NewGuid().guid

#region create config on Pull Server
configuration telnet {
    param (
        $GUID
    )
    node $GUID {
        WindowsFeature telnetclient {
            Ensure = 'Present'
            Name = 'Telnet-Client'
        }
    }
}
telnet -GUID $GUID -OutputPath 'C:\Program Files\WindowsPowerShell\DscService\Configuration\'
New-DSCCheckSum -ConfigurationPath "C:\Program Files\WindowsPowerShell\DscService\Configuration\$GUID.mof"
#endregion create config on Pull Server

#region Configure LCM on dscclient01
configuration LCM {
    param (
        [Parameter(Mandatory)]
        [String] $GUID,

        [Parameter(Mandatory)]
        [String] $PullServerURL,

        [Parameter(Mandatory)]
        [String] $PullServerPort,

        [Parameter(Mandatory)]
        [Bool] $AllowUnsecureConnection,

        [Parameter(Mandatory)]
        [String] $Node
    )

    [String]$AllowUnsecure = $AllowUnsecureConnection.ToString($_)
    node $Node {
        LocalConfigurationManager {
            RefreshMode = 'Pull'
            ConfigurationMode = 'ApplyAndAutoCorrect'
            ConfigurationID = $GUID
            ActionAfterReboot = 'ContinueConfiguration'
            DownloadManagerCustomData = @{
                                        ServerUrl = "$PullServerURL`:$PullServerPort/PSDSCPullServer.svc";
				                        AllowUnsecureConnection = $AllowUnsecure;
                                        }
            DownloadManagerName = 'WebDownloadManager'
            ConfigurationModeFrequencyMins = 15
            RefreshFrequencyMins = 30
            RebootNodeIfNeeded = $true
            DebugMode = 'All'
        }
    }
}
$LCMHTTPArgs = @{
    OutputPath = 'c:\Configs\LCM';
    GUID = $GUID;
    PullServerURL = "http://$env:computername";
    PullServerPort = '8080';
    AllowUnsecureConnection = $true;
    Node = 'DSCClient01';
}

LCM @LCMHTTPArgs
$C = New-CimSession -ComputerName dscclient01
Get-DscLocalConfigurationManager -CimSession $c
Set-DscLocalConfigurationManager -CimSession $c -Path C:\Configs\LCM -Verbose
Get-DscLocalConfigurationManager -CimSession $c
Get-DscLocalConfigurationManager -CimSession $c | % DownloadManagerCustomData
#endregion Configure LCM on dscclient01

#region pull
Update-DscConfiguration -CimSession $c -Wait -Verbose
#endregion pull

#region cleanup
$C | Remove-CimSession
#endregion cleanup