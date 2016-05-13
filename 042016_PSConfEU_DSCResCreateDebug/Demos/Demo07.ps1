#invoke bugs!
Start-DscConfiguration -UseExisting -CimSession $cimsession -Wait -Verbose #triggers bug

#invoke bugs again
$pssession | Enter-PSSession
Invoke-DscResource -Name SMBShare -Method Test -Property @{Name = 'MyShare';Path = 'c:\myshare';Ensure='Present'} -ModuleName psconfeu -Verbose #triggers bug
Exit-PSSession

# Remote Debug the resource and apply fixes
Enable-DscDebug -BreakAll -CimSession $cimsession
Start-DscConfiguration -UseExisting -CimSession $cimsession -Wait -Verbose #triggers bug

$pssession | Enter-PSSession
psedit (Get-ChildItem -Path (Get-DscResource -Module PSConfEU).ParentPath -Filter *.psm1).fullname
Exit-PSSession

#post debugging validation
Get-SmbShare -CimSession $cimsession -Name myshare | Get-SmbShareAccess
Get-SmbShare -CimSession $cimsession -Name myshare | Grant-SmbShareAccess -AccountName users -AccessRight full
Disable-DscDebug -CimSession $cimsession
Start-DscConfiguration -UseExisting -CimSession $cimsession -Wait -Verbose