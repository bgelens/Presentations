#region manual
Start-Transcript #Now also works in ISE
gps
$temp = Stop-Transcript
psEdit $temp.Split(' ')[-1]
#endregion

#region policy
gpedit.msc
#Computer Policy -> Administrative Templates -> Windows Components -> Windows PowerShell
#Enable Global transcription

New-Item -Path c:\somebadcode.ps1 -Value 'function foo {param($Name)"Hello {0}" -f $Name}'
Start-Process PowerShell.exe
#. C:\somebadcode.ps1
#foo -Name CDC!
#endregion

#region Enable Script block logging
eventvwr #Microsoft-Windows-PowerShell/Operational

Start-Process PowerShell.exe
#. C:\somebadcode.ps1
#foo -Name CDC!
#endregion