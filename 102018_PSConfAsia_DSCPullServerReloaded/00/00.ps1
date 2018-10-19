$passwordFile = Get-Content .\password.json | ConvertFrom-Json
$hostCred = [pscredential]::new($passwordFile.UserName, ($passwordFile.Password | ConvertTo-SecureString -AsPlainText -Force))
$edbsession = New-PSSession -Credential $hostCred -ComputerName edbpull.mshome.net
$lcmsession = New-PSSession -Credential $hostCred -ComputerName dscclient.mshome.net
$sqlsession = New-PSSession -Credential $hostCred -ComputerName sqlpull.mshome.net