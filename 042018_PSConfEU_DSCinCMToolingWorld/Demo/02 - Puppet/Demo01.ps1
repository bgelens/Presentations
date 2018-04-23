break

#region move to normal PS Host
if ($host.Name -eq 'Visual Studio Code Host') {
    Write-Warning -Message 'ctrl + shift + t'
}
Remove-Module -Name PSReadLine
#endregion

#region start demo
$passwordFile = Get-Content .\password.json | ConvertFrom-Json
$puppetclientCred = [pscredential]::new($passwordFile.UserName, ($passwordFile.Password | ConvertTo-SecureString -AsPlainText -Force))
$session = New-PSSession -ComputerName puppetclient.mshome.net -Credential $puppetclientCred
Enter-PSSession -Session $session
#endregion

#region puppet agent is already installed
Get-Command -Name puppet
puppet --version
#endregion

#region types and modules that are installed out of the box
# puppet resource --types
# puppet module list
#endregion

#region find and install dsc module
puppet module search dsc
#puppet module install puppetlabs-dsc #https://forge.puppet.com/puppetlabs/dsc #supported
#pre-installed to save time
puppet module list
#endregion

#region new types
puppet resource --types | Where-Object -FilterScript {$_ -like "dsc*"} | Select-Object -First 10
ls C:\ProgramData\PuppetLabs\code\environments\production\modules\dsc\lib\puppet\type\ | Select-Object -First 10
tree /A /F C:\ProgramData\PuppetLabs\code\environments\production\modules\dsc\lib\puppet_x\dsc_resources\xTimeZone
#endregion

#region example usage
Get-TimeZone

@'
dsc_xtimezone { 'amsterdamtime' :
  dsc_issingleinstance => 'yes',
  dsc_timezone => 'W. Europe Standard Time',
}
'@ | Out-File .\timezone.pp -Encoding ascii -Force
puppet apply .\timezone.pp

Get-TimeZone

# see how DSC was triggered
Get-DscConfigurationStatus | Select-Object -Property *

# did the module install that resource?
Get-DscResource

# how did this work? #line 59
Get-Content C:\ProgramData\PuppetLabs\code\environments\production\modules\dsc\lib\puppet\provider\templates\dsc\invoke_dsc_resource.ps1.erb
(Get-Content C:\ProgramData\PuppetLabs\code\environments\production\modules\dsc\lib\puppet\provider\templates\dsc\invoke_dsc_resource.ps1.erb)[58]

# so no conflicts with installed resources and such but extending is hard as need to build your own version of this module

# remove
puppet module uninstall puppetlabs-dsc
#endregion

#region install dsc_lite module
#puppet module install puppetlabs-dsc_lite #https://forge.puppet.com/puppetlabs/dsc_litels

#predownloaded to save time
Copy-Item C:\Users\Administrator\Documents\dsc_lite -Destination C:\ProgramData\PuppetLabs\code\environments\production\modules -Recurse
puppet module list
#endregion

#region new types
# puppet resource --types | Where-Object -FilterScript {$_ -like "dsc*"} | Select-Object -First 10
#endregion

#region example usage
@'
dsc { 'script resource' :
    dsc_resource_name   => 'script',
    dsc_resource_module => {
        name    => 'PSDesiredStateConfiguration',
        version => '1.1'
    },
    dsc_resource_properties  => {
        getscript => '
            @{}
        ',
        setscript => '
            Write-Verbose -Message "Executing SetScript"
            $msg = "Running as: $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)"
            Write-Verbose -Message $msg
            $msg | Out-File c:\windows\temp\test.txt
        ',
        testscript => '
            Write-Verbose -Message "Executing TestScript"
            $false
        ',
        psdscrunascredential => {
            'dsc_type' => 'MSFT_Credential',
            'dsc_properties' => {
              'user'     => 'Administrator',
              'password' => 'Welkom01'
            }
        },
    },
}
'@ | Out-File .\diffcred.pp -Encoding ascii -Force
Test-Path c:\windows\temp\test.txt
puppet apply .\diffcred.pp
Get-Content -Path c:\windows\temp\test.txt
#endregion

#region interaction with LCM
Get-DscConfigurationStatus
Get-ChildItem -Path C:\Windows\System32\Configuration\ConfigurationStatus *.json | 
    Sort-Object -Property LastWriteTime -Descending |
    Select-Object -First 1 |
    Get-Content -Encoding Unicode | ConvertFrom-Json

# no LCM config
Get-ChildItem -Path C:\Windows\System32\Configuration\ -Filter *.mof
#endregion
