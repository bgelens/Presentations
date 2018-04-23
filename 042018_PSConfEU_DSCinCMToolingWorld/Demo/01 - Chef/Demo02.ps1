break

#region move to normal PS Host
if ($host.Name -eq 'Visual Studio Code Host') {
    Write-Warning -Message 'ctrl + shift + t'
}
Remove-Module -Name PSReadLine
#endregion

#region start demo
$passwordFile = Get-Content .\password.json | ConvertFrom-Json
$chefclientCred = [pscredential]::new($passwordFile.UserName, ($passwordFile.Password | ConvertTo-SecureString -AsPlainText -Force))
$session = New-PSSession -ComputerName chefclient.mshome.net -Credential $chefclientCred
Enter-PSSession -Session $session
#endregion

#region show LCM
Get-DscLocalConfigurationManager
Get-DscConfigurationStatus -ErrorAction SilentlyContinue
Get-DscConfiguration -ErrorAction SilentlyContinue
#endregion

#region dsc_script intro
@'
dsc_script 'dsc-script-resource' do
  code <<-EOH
    Script 'whoami' {
        GetScript = {
            @{
                GetScript = $GetScript
                SetScript = $SetScript
                TestScript = $TestScript
                Result = $null
            }
        }
        SetScript = {
            Write-Verbose -Message "Executing SetScript"
            Write-Verbose -Message "Running as: $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)"
        }
        TestScript = {
            Write-Verbose -Message "Executing TestScript"
            $false
        }
    }
  EOH
end
'@ | Out-File .\dscscript01.rb -Encoding utf8 -Force

chef-client --local-mode .\dscscript01.rb

Get-DscConfigurationStatus
Get-DscConfiguration
Test-DscConfiguration -Verbose
Start-DscConfiguration -Wait -Verbose -UseExisting
#endregion

#region using diff credentials
@'
dsc_script 'dsc-script-resource' do
  code <<-EOH
    Script 'whoami' {
        GetScript = {
            @{
                GetScript = $GetScript
                SetScript = $SetScript
                TestScript = $TestScript
                Result = $null
            }
        }
        SetScript = {
            Write-Verbose -Message "Executing SetScript"
            Write-Verbose -Message "Running as: $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)"
        }
        TestScript = {
            Write-Verbose -Message "Executing TestScript"
            $false
        }
        PsDscRunAsCredential = #{ps_credential('Administrator', 'Welkom01')}
    }
  EOH
  configuration_data <<-EOH
    @{
      AllNodes = @(
        @{
          NodeName = 'localhost'
          PsDscAllowPlainTextPassword = $true
        }
      )
    }
  EOH
end
'@ | Out-File .\dscscript03.rb -Encoding utf8 -Force
# chef-client --local-mode .\dscscript03.rb
# Start-DscConfiguration -Wait -Verbose -UseExisting
#endregion

#region dependson
@'
dsc_script 'dsc-script-resource' do
  code <<-EOH
    Script 'whoami' {
        GetScript = {
            @{
                GetScript = $GetScript
                SetScript = $SetScript
                TestScript = $TestScript
                Result = $null
            }
        }
        SetScript = {
            Write-Verbose -Message "Executing SetScript"
            Write-Verbose -Message "Running as: $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)"
        }
        TestScript = {
            Write-Verbose -Message "Executing TestScript"
            $false
        }
        #DependsOn = '[Script]whoareyou' #As normal, uncomment to change execution order
    }

    Script 'whoareyou' {
        GetScript = {
            @{
                GetScript = $GetScript
                SetScript = $SetScript
                TestScript = $TestScript
                Result = $null
            }
        }
        SetScript = {
            Write-Verbose -Message "Executing SetScript"
            Write-Verbose -Message "Running as: $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)"
        }
        TestScript = {
            Write-Verbose -Message "Executing TestScript"
            $false
        }
    }
  EOH
end
'@ | Out-File .\dscscript04.rb -Encoding utf8 -Force
# chef-client --local-mode .\dscscript04.rb
#endregion

#region custom resource
Install-Module -Name xNetworking -Force
# in case of bad internet
Copy-Item ~\Documents\xNetworking 'C:\Program Files\WindowsPowerShell\Modules' -Recurse

@'
dsc_script 'dsc-host-file' do
  code <<-EOH
    xHostsFile somehost {
        HostName = 'thehost'
        IPAddress = '127.0.0.1'
        Ensure = 'Present'
    }
  EOH
  imports 'xNetworking'
end
'@ | Out-File .\dscscript05.rb -Encoding utf8 -Force
# chef-client --local-mode .\dscscript05.rb
# Get-DscConfiguration
# Get-Content C:\Windows\System32\drivers\etc\hosts
# Test-NetConnection -ComputerName thehost
#endregion

#region cleanup
Get-ChildItem *.rb | Remove-Item
Remove-DscConfigurationDocument -Stage Current, Pending, Previous
Get-ChildItem -Path C:\Windows\System32\Configuration\ConfigurationStatus | Remove-Item -Force
#endregion
