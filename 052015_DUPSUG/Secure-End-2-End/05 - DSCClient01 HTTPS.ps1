#$GUID = (Get-ChildItem -Path 'C:\Program Files\WindowsPowerShell\DscService\Configuration' -Filter *.mof).Name.Trimend('.mof')

#region reconfigure LCM on DSCClient01
configuration AuthLCM {
    param (
        [Parameter(Mandatory)]
        [String] $GUID,

        [Parameter(Mandatory)]
        [String] $PullServerURL,

        [Parameter(Mandatory)]
        $PullServerPort,

        [bool] $AllowUnsecureConnection = $false,

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

$LCMHTTPSArgs = @{
    OutputPath = 'c:\Configs\AuthLCM';
    GUID = $GUID;
    PullServerURL = "https://$env:computername";
    PullServerPort = '443';
    AllowUnsecureConnection = $false;
    Node = 'DSCClient01';
}

AuthLCM @LCMHTTPSArgs
$C = New-CimSession -ComputerName dscclient01
Set-DscLocalConfigurationManager -CimSession $c -Path C:\Configs\AuthLCM -Verbose
Get-DscLocalConfigurationManager -CimSession $c | % DownloadManagerCustomData
#endregion reconfigure LCM on DSCClient01

#region pull
Update-DscConfiguration -CimSession $c -Wait -Verbose
#endregion pull

#region import root ca cert
Invoke-Command -ComputerName dscclient01 -ScriptBlock {
    Invoke-WebRequest http://cdp.domain.tld/PSDSC-CA.crt -OutFile $env:TEMP\PSDSC-CA.crt -Verbose
    Import-Certificate -FilePath $env:TEMP\PSDSC-CA.crt -CertStoreLocation Cert:\LocalMachine\Root -Verbose
}
#endregion import root ca cert

#region pull
Update-DscConfiguration -CimSession $c -Wait -Verbose
#endregion pull

#region cleanup
$C | Remove-CimSession
#endregion cleanup