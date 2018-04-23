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

#region chef client is already installed
Get-Command -Name chef-client
chef-client --version
#endregion

#region dsc / powershell resource we can use out of the box
Get-ChildItem -Path 'C:\opscode\chef\embedded\lib\ruby\gems\2.4.0\gems\chef-13.7.16-universal-mingw32\lib\chef\provider' -Filter *.rb |
    Where-Object -FilterScript {$_.Name -match "^dsc|powershell"}
#endregion
