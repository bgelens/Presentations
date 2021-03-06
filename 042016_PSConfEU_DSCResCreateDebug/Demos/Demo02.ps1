$TestArgs = @{
    Ensure = 'Present'
    Path = 'c:\myshare'
    Name = 'MyShare'
}

#use Invoke-DscResource to call Method. In early versions of WMF5 LCM should be in disabled refreshmode. From WMF5 RTM on, requirement has dropped
Invoke-DscResource -Name SMBShare -ModuleName PSConfEU -Method Test -Property $TestArgs -Verbose

#region update resource
Get-ChildItem -Path (Get-DscResource -Module PSConfEU).ParentPath -Filter *.psm1 | %{psEdit $_.FullName}
    # Write-Verbose -Message "See me yet?????????????????"
#endregion

#Invoke-DscResource again, see me yet?
Invoke-DscResource -Name SMBShare -ModuleName PSConfEU -Method Test -Property $TestArgs -Verbose

#region update LCM
[DscLocalConfigurationManager()]
configuration LCM {
    Settings {
        DebugMode = 'ForceModuleImport'
    }
}
LCM
Set-DscLocalConfigurationManager -Path .\LCM -Force -Verbose 
#endregion

#Invoke-DscResource again, see me yet?
Invoke-DscResource -Name SMBShare -ModuleName PSConfEU -Method Test -Property $TestArgs -Verbose