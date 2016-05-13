$SolutionDir = $DTE.ActiveDocument.Path

# // show onboard from Portal UI

#region Download Onboard Meta MOF
$AAAccount | Get-AzureRmAutomationDscOnboardingMetaconfig -OutputFolder $SolutionDir -Force
ii $SolutionDir\DscMetaConfigs\localhost.meta.mof
#endregion Download Onboard Meta MOF

#region construct Onboard Meta MOF
[DscLocalConfigurationManager()]
configuration LCM {
    Settings {
        RefreshMode = 'Pull'
        ConfigurationMode = 'ApplyAndAutoCorrect'
        ActionAfterReboot = 'ContinueConfiguration'
        RebootNodeIfNeeded = $true
        ConfigurationModeFrequencyMins = 15
        RefreshFrequencyMins = 30
        AllowModuleOverwrite = $true
    }
    ConfigurationRepositoryWeb DSCaaS {
        RegistrationKey = $Keys.PrimaryKey
        ServerURL = $Keys.EndPoint
    }
    ResourceRepositoryWeb DSCaaS {
        RegistrationKey = $Keys.PrimaryKey
        ServerURL = $Keys.EndPoint
    }
    ReportServerWeb DSCaaS {
        RegistrationKey = $Keys.PrimaryKey
        ServerURL = $Keys.EndPoint
    }
}
lcm -OutputPath $SolutionDir
ii $SolutionDir\localhost.meta.mof
#endregion Construct Onboard Meta MOF

#region Onboard Windows VM EL201502
#Create session
$EL201502Cred = [pscredential]::new('ben', $AzureCred.password)
$EL201502Session = New-PSSession -ComputerName el201502.westeurope.cloudapp.azure.com -Credential $EL201502Cred

#copy over meta.mof over session
Copy-Item -Path $SolutionDir\localhost.meta.mof -Destination c:\ -ToSession $EL201502Session -Force
#Copy-Item -Path $SolutionDir\DscMetaConfigs\localhost.meta.mof -Destination C:\ -ToSession $EL201502Session -Force

#enter the session
$EL201502Session | Enter-PSSession

#show current config
$PSVersionTable
Get-DscLocalConfigurationManager

#onboard the node
Set-DscLocalConfigurationManager -Path c:\ -Verbose
#show portal

#show local configuration
Get-Content C:\Windows\System32\Configuration\Metaconfig.mof -Encoding Unicode
Get-Content c:\localhost.meta.mof | Select-String 'RegistrationKey'
Remove-Item c:\localhost.meta.mof -Force

#show LCM
Get-DscLocalConfigurationManager | select *ID* #show in portal

#show authentication cert (does not get autorenewed yet)
Get-ChildItem -Path cert:\localmachine\my | select *
Get-DscLocalConfigurationManager | Format-Custom

#exit pssession
Exit-PSSession

$AAAccount | Get-AzureRmAutomationDscNode
#endregion Onboard Windows VM