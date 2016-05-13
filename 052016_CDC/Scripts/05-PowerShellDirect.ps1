#region pssession
$PassWord = (ConvertTo-SecureString -String 'P@ssw0rd!' -AsPlainText -Force)
$Cred = [pscredential]::new('Administrator',$PassWord)
$NanoSession = New-PSSession -VMName Nano-01 -Credential $Cred
#endregion

#region Invoke-Command
#Invoke-Command has PSDirect capabilities itself!
Invoke-Command -VMName Nano-01 -Credential $Cred -ScriptBlock {
    Get-CimInstance -ClassName Win32_OperatingSystem
}
#or over PSSession
Invoke-Command -Session $NanoSession -ScriptBlock {
    Get-CimInstance -ClassName Win32_OperatingSystem
}
#endregion

#region Copy-File (known bug in my current build, may BSOD!)
Copy-Item -Path C:\Windows\System32\calc.exe -Destination c:\ -ToSession $NanoSession
#endregion

#region enter-pssession
$NanoSession | Enter-PSSession
Get-ChildItem -Path c:\
Get-Service -Name wuauserv | Restart-Service -Force
Exit-PSSession
#endregion