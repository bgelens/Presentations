#region variables
$GUID = [System.Guid]::NewGuid().guid
$CERPath = 'C:\PublicCerts'
if (!(Test-Path $CERPath)) {
    New-Item $CERPath -Force -ItemType Directory
}
$certfile = "$CERPath\$GUID.cer"
#endregion variables

#region acquire encryption cert
Invoke-Command -ComputerName DSCClient01 -ScriptBlock {
    $SecString = 'Pa$sW0rd!' | ConvertTo-SecureString -AsPlainText -Force
    $CertReqArgs = @{
        Url = 'https://webenroll.domain.tld/ADPolicyProvider_CEP_UsernamePassword/service.svc/CEP';
        Template = 'DSCEncryption';
        SubjectName = "CN=$using:GUID";
        CertStoreLocation = 'Cert:\LocalMachine\My'
        Credential = New-Object System.Management.Automation.PsCredential('Domain\User', $SecString)
    }
    $cert = Get-Certificate @CertReqArgs -Verbose
    [System.Convert]::ToBase64String($Cert.Certificate.GetRawCertData(), 'InsertLineBreaks')
} -OutVariable 'PublicCert'
#endregion acquire encryption cert
 
#region output pulic cert to dir
$PublicCert | Out-File -FilePath $certfile -Force
ii $certfile

#import cert in mem to access thumbprint later on
$certPrint = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
$certPrint.Import($certfile)
#endregion output public cert to dir

#region configuration data
$ConfigData = @{   
    AllNodes = @(        
        @{     
            NodeName = $GUID
            CertificateFile=$certfile
        } 
    )  
} 
#endregion configuration data

#region configuration
configuration LocalAdmin {
    param (
        [String] $Node,
 
        [PSCredential] $Credential
    )
    node $Node {
        User LocalAdmin {
            UserName = $Credential.UserName
            Ensure = 'Present'
            Password = $Credential
            Description = 'User created by DSC'
            PasswordNeverExpires = $true
            PasswordChangeNotAllowed = $true
        }
 
        Group Administrators {
            GroupName = 'Administrators'
            MembersToInclude = $Credential.UserName
            DependsOn = "[User]LocalAdmin"
        }
    }
}
#endregion configuration
 
#region create MOF file
LocalAdmin -Node $GUID `
           -Credential (New-Object System.Management.Automation.PsCredential('DSCAdmin', ('MyPassWord!' | ConvertTo-SecureString -AsPlainText -Force))) `
           -OutputPath 'C:\Program Files\WindowsPowerShell\DscService\Configuration' `
           -ConfigurationData $ConfigData
 
New-DSCCheckSum -ConfigurationPath "C:\Program Files\WindowsPowerShell\DscService\Configuration\$GUID.mof" -Force
psedit "C:\Program Files\WindowsPowerShell\DscService\Configuration\$GUID.mof"
#endregion create MOF file

#region reconfigure LCM
configuration AuthLCM {
    param (
        [Parameter(Mandatory)]
        [String] $GUID,

        [Parameter(Mandatory)]
        [String] $PullServerURL,

        [Parameter(Mandatory)]
        $PullServerPort,

        [bool]$AllowUnsecureConnection = $false,

        [Parameter(Mandatory)]
        [String] $Node,

        [Parameter(Mandatory)]
        [String] $CertificateId,

        [Parameter(Mandatory)]
        [String] $EncryptionCertID
    )

    [String]$AllowUnsecure = $AllowUnsecureConnection.ToString($_)

    node $Node {
        LocalConfigurationManager {
            CertificateID = $EncryptionCertID
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

$LCMHTTPSArgs = @{
    OutputPath = 'c:\Configs\AuthLCM';
    GUID = $GUID;
    PullServerURL = "https://$env:computername";
    PullServerPort = '443';
    AllowUnsecureConnection = $false;
    Node = 'DSCClient01';
    CertificateID = $cert.Certificate.Thumbprint;
    EncryptionCertID = $certPrint.Thumbprint;
}

AuthLCM @LCMHTTPSArgs
$C = New-CimSession -ComputerName dscclient01
Set-DscLocalConfigurationManager -CimSession $c -Path C:\Configs\AuthLCM -Verbose
Get-DscLocalConfigurationManager -CimSession $c
#endregion reconfigure LCM

#region pull
Update-DscConfiguration -CimSession $c -Wait -Verbose
#endregion pull

#region cleanup
$C | Remove-CimSession
#endregion cleanup