#region create local user for Cert mapping
# nice simple password generation one-liner by G.A.F.F Jakobs
# https://gallery.technet.microsoft.com/scriptcenter/Simple-random-code-b2c9c9c9
$DSCUserPWD = ([char[]](Get-Random -InputObject $(48..57 + 65..90 + 97..122) -Count 12)) -join '' 
        
$Computer = [ADSI]'WinNT://.,Computer'
$DSCUser = $Computer.Create('User', 'DSCUser')
$DSCUser.SetPassword($DSCUserPWD)
$DSCUser.SetInfo()
$DSCUser.Description = 'DSC User for Client Certificate Authentication binding '
$DSCUser.SetInfo()
$DSCUser.UserFlags = 64 + 65536 # ADS_UF_PASSWD_CANT_CHANGE + ADS_UF_DONT_EXPIRE_PASSWD
$DSCUser.SetInfo()
([ADSI]'WinNT://./IIS_IUSRS,group').Add('WinNT://DSCUser,user')  
#endregion create local user for Cert mapping

#region configure require Client cert
Install-WindowsFeature -Name Web-Cert-Auth
Set-WebConfiguration -PSPath IIS:\ -Filter //access -Metadata overrideMode -value Allow -Force
Set-WebConfiguration -PSPath IIS:\ -Filter //iisClientCertificateMappingAuthentication -Metadata overrideMode -value Allow -Force
Set-WebConfiguration -PSPath IIS:\Sites\PSDSCPullServer -Filter 'system.webserver/security/access' -Value 'Ssl, SslNegotiateCert, SslRequireCert, Ssl128' -Force

@(
    #Enable client certificate auth
    @{
        PSPath = 'IIS:\Sites\PSDSCPullServer';
        Filter = 'system.webServer/security/authentication/iisclientCertificateMappingAuthentication';
        Name = 'enabled';
        Value = 'True';
    },

    #Enable many to one mapping feature
    @{
        PSPath = 'IIS:\Sites\PSDSCPullServer';
        Filter = 'system.webServer/security/authentication/iisclientCertificateMappingAuthentication';
        Name = 'manyToOneCertificateMappingsEnabled';
        Value = 'True';
    },

    #Disable on to one mapping feature
    @{
        PSPath = 'IIS:\Sites\PSDSCPullServer';
        Filter = 'system.webServer/security/authentication/iisclientCertificateMappingAuthentication';
        Name = 'oneToOneCertificateMappingsEnabled';
        Value = 'False';
    }
) | %{
    Set-WebConfigurationProperty @_
}
#endregion configure require Client cert

#region configure certificate mapping
@(
    #Create many to one mapping with local account. If a rule matches, these credentials are used.
    @{
        PSPath = 'IIS:\Sites\PSDSCPullServer';
        Filter = 'system.webServer/security/authentication/iisClientCertificateMappingAuthentication/manyToOneMappings';
        Name = '.';
        Value = @{
            name = 'DSC Pull Client';
            description = 'DSC Pull Client';
            userName    = 'DSCUser';
            password    = $DSCUserPWD;
        };
    },

    #Create many to one rule for previous mapping to map certificates issued by PSDSC-CA CA to the local account
    @{
        PSPath = 'IIS:\Sites\PSDSCPullServer';
        Filter = "system.webServer/security/authentication/iisClientCertificateMappingAuthentication/manyToOneMappings/add[@name='DSC Pull Client']/rules";
        Name = '.';
        Value = @{
            certificateField     = 'Issuer';
            certificateSubField  = 'CN';
            matchCriteria        = 'PSDSC-CA';
            compareCaseSensitive = 'False';
        };
    },

    #Add deny rule for all CA's we trust but don't want to provide access to the Pull Server
    @{
        PSPath = 'IIS:\Sites\PSDSCPullServer';
        Filter = 'system.webServer/security/authentication/iisClientCertificateMappingAuthentication/manyToOneMappings';
        Name = '.';
        Value = @{
            name           = 'Deny'
            description    = 'Deny'
            permissionMode = 'Deny'
        };
    }
) | % {
    Add-WebConfigurationProperty @_
}
#endregion configure certificate mapping

#region show access denied
$C = New-CimSession -ComputerName dscclient01
Get-DscLocalConfigurationManager -CimSession $c | % DownloadManagerCustomData
#endregion show access denied

#region pull
Update-DscConfiguration -CimSession $c -Wait -Verbose
#endregion pull

#region cleanup
$C | Remove-CimSession
#endregion cleanup