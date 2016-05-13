#$GUID = (Get-ChildItem -Path 'C:\Program Files\WindowsPowerShell\DscService\Configuration' -Filter *.mof).Name.TrimEnd('.mof')

#region acquire LCM Auth cert
$Cert = Invoke-Command -ComputerName DSCClient01 -ScriptBlock {
    $SecString = 'Pa$sW0rd!' | ConvertTo-SecureString -AsPlainText -Force

    $CertReqParams = @{
        Url = 'https://webenroll.domain.tld/ADPolicyProvider_CEP_UsernamePassword/service.svc/CEP';
        Template = 'DSCPullClientAuth';
        SubjectName = "CN=$env:COMPUTERNAME"
        Credential = New-Object System.Management.Automation.PsCredential('Domain\User', $SecString);
        CertStoreLocation = 'Cert:\LocalMachine\My';
    }
    $Certificate = Get-Certificate @CertReqParams
    return $Certificate
}
#endregion acquire LCM Auth cert

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
        [String] $Node,

        [Parameter(Mandatory)]
        [String] $CertificateID
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
                                        CertificateID = $CertificateID;
                                        }
            DownloadManagerName = 'WebDownloadManager'
            ConfigurationModeFrequencyMins = 15
            RefreshFrequencyMins = 30
            RebootNodeIfNeeded = $true
            DebugMode = 'All'
        }
    }
}

$LCMAuthArgs = @{
    OutputPath = 'c:\Configs\AuthLCM';
    GUID = $GUID;
    PullServerURL = "https://$env:computername";
    PullServerPort = '443';
    AllowUnsecureConnection = $false;
    Node = 'DSCClient01';
    CertificateID = $cert.Certificate.Thumbprint;
}

AuthLCM @LCMAuthArgs

$C = New-CimSession -ComputerName dscclient01
Set-DscLocalConfigurationManager -CimSession $c -Path C:\Configs\AuthLCM -Verbose
Get-DscLocalConfigurationManager -CimSession $c | % DownloadManagerCustomData
#endregion reconfigure LCM on DSCClient01

#region pull
Update-DscConfiguration -CimSession $c -Wait -Verbose
#endregion pull

#region cleanup
$C | Remove-CimSession
#endregion cleanup