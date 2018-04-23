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

#region onboard VM to chef server

'-----BEGIN RSA PRIVATE KEY-----
MIIEpQIBAAKCAQEA7nnbGrZACkP2mdGMIj8dFyAHlvcSmLBEgrmt/e2F1OtdnrAb
WD0QPI0FHKTLzWsUR/s8YaaCog30cinzHQZNB7nTRnFmeRrMx7OItuZmKflg6hIg
ioDDs4V85+Kn9PYElB6hW7RcL7L8OeJlmtDX1ZWgQK85AXSc1zTCz09qQ2cys0pV
/DdIz2f7nt8KpsXddfcpLnmGt82quAnvk7UU4OMqxBJ2XWuaPKimBcMWICfnET7N
PmoOc6q0/dNnIyXF/P4HM/HvGdFhhv85e/bWGkAm3aRvmWOpgZ8Pi51tD1W6Of3Y
GRGb4Bqk+ziBNJvf1Et9dOoetiCY+vvw9LSVcQIDAQABAoIBAQDIX8cD6MJiXbyk
ffd7BwDQX29BH5SWivTlylIxnBPpVWIyZdJ0D8rGtc7nxGghz6kY2jZf7mKw+3y7
OBg3+QVcSn0FIV9yvlv2KBnlZC3PcuRFiLmi5pKJEs5ioIVzRAuQ0TPPM/qJcaCQ
mnO442WW5sPh1djWKj9ma8SMIDQvMLWWJPfLAjL7Wsfd9hoQjR0OmfG86KOXUGqa
0tFgF/NWu93qTE7LrL4EtrlUlNzmZtkBpZ+X9qd3pFEYQQIt5uviphXZMhXDLyIt
6Yb6EBPo4lOOPuxN3cRddj/tLHghonEUXiRZJz936AFAeNt8FIrRHPTAI6r7YqUN
/vNthsFhAoGBAPuO2bKhNo/iJ5C88ukt+Rj2AGIr0ADM7uRxN6TBTaEamfe62/LH
UBQ8gfawz1LXCie2ZdRTiOjaIlLShpFqMKLJqH5cC3yklvqru7J/NTcMhDBrQQpP
ZhRGuAsCVN6pyqYpg5lRNxgD+07iMJn64QvcsH4suPabu1rcDLvflqcNAoGBAPKv
3oV41wVsRZTb9moFRuEQfuXF9qpuP/58dsMyr/XNj4RArvHvLxGx/T5pY15LfQRQ
unzpso69SMg9PEEvC6YW63Ye4+UfmWuaVnHH2J/gbwBrvO6kyzloQ6DDSDcnVmI4
El2KoOlXZ/nGwMFxkrQHyPBc7wsKy5eeqPuU9A71AoGAYW4vhQ8JmerG1jlIf+XN
b8x/04YSluzIrfPn0EkKLxalgZx+6eYmbuAMmiZa9kPRbBYqFHWSNlWeK6PceN+/
HJ2sQ9yUml8JFueC2ByK2NphLHuuAjdEWyAU0jbB9kee9IJptO0OwJ9yK1hR6KGR
nk2IkiXyMZmZlBRcXju4FtUCgYEA14GvM41EO++StobCAhHfiDrSxQ4PZfbzYvR5
rgsT0E4TNNkPwY2pmagZ/1Msx253fN6HTCdmxXR27kHagPPa/0l5HHJ/41Y1MiVi
wDU8O3TcfV4u7yhtwvPAokDnnvqSrjOms2RIUg2pKlgBkYZeRPpoyHFuYLrcYi6l
VotGUwUCgYEA017CYYE8NYbf57QHvmO4urPXQ7FwMh6RiFJo+MfgfXSL/IfvuUn6
zcldBID3aWyotUc8DX6y4fb95bexp5DrarN6e597rJHRHZi279aRgILQU/Ykjluv
9zM9FxiTNjqpB1i+tXT64tu84E9sWnrjtyvK1DO1ueOLYmwDznkZL8s=
-----END RSA PRIVATE KEY-----' | Out-File C:\chef\validator.pem -Encoding ascii

$chefOrg = 'bgelens'
$chefServerUri = 'https://chefserver.mshome.net/organizations/{0}' -f $chefOrg
@"
chef_server_url        '$chefServerUri'
validation_client_name '$chefOrg-validator'
validation_key         'C:\chef\validator.pem'
node_name              '$($env:COMPUTERNAME.ToLower())'
ssl_verify_mode        :verify_none
"@ | Out-File -FilePath c:\chef\client.rb -Encoding utf8 -Force

Get-Content -Path c:\chef\client.rb

chef-client --runlist 'recipe[PSCONFEU::containerHost]'
#endregion

#region adjust run-list
# go to portal and adjust
# introduce change event
Stop-Service docker
Remove-Item -Path C:\ProgramData\docker\config\daemon.json -Force
chef-client

Get-Content -Path C:\ProgramData\Docker\config\daemon.json
docker info
#endregion

#region show reporting
# go to portal
#endregion
