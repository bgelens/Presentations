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

#region join puppetserver
cat C:\ProgramData\PuppetLabs\puppet\etc\puppet.conf
((cat C:\ProgramData\PuppetLabs\puppet\etc\puppet.conf) -replace 'server=puppet', 'server=puppetserver.mshome.net') |
    Out-File C:\ProgramData\PuppetLabs\puppet\etc\puppet.conf -Encoding ascii

puppet agent --test
#endregion

#region report
# show web report
#endregion

#region introduce change and look at report again
Remove-Item C:\ProgramData\docker\config\daemon.json
puppet agent --test
# show web report
#endregion

#region puppet cache
# no modules are maintained on node
puppet module list

# instead the puppet agent downloads all is needed into a cache
tree /A /F C:\ProgramData\PuppetLabs\puppet\cache
$cat = cat C:\ProgramData\PuppetLabs\puppet\cache\client_data\catalog\puppetclient.mshome.net.json | ConvertFrom-Json
$cat
$cat.resources[4..14] | ft
$cat.resources[5].parameters | fl
#endregion
