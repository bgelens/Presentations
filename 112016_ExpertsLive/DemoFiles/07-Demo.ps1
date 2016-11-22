# Remote Debug the resource and apply fixes
Enable-DscDebug -BreakAll -CimSession $cimsession
Start-DscConfiguration -UseExisting -CimSession $cimsession -Wait -Verbose #triggers bug

$pssession | Enter-PSSession
psedit (Get-ChildItem -Path (Get-DscResource -Module ExpertsLive).ParentPath -Filter *.psm1).fullname
Exit-PSSession

# Disable debugging and assert again
Disable-DscDebug -CimSession $cimsession
Start-DscConfiguration -UseExisting -CimSession $cimsession -Wait -Verbose

#post debugging validation
$pssession | Enter-PSSession
#refresh path
$env:Path = (gcim win32_environment -Filter 'systemvariable = True and Name = "Path"').VariableValue
docker version
Exit-PSSession
