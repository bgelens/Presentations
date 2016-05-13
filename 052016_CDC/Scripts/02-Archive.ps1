#region explore Module cmdlets
Get-Module -Name Microsoft.PowerShell.Archive -ListAvailable
#now also in PSGallery OSS and down-level support PS4+
Find-Module -Name Microsoft.PowerShell.Archive
Get-Command -Module Microsoft.PowerShell.Archive
#endregion

#region create Archive
$CompressArg = @{
    Path = 'C:\Windows\System32\Sysprep\Panther'
    DestinationPath = 'C:\Sysprep.zip'
    CompressionLevel = 'Fastest' #NoCompression, Optimal
    #Force = $true #Overwrite Archive if exists
    Verbose = $true
}
Compress-Archive @CompressArg
Get-Item -Path C:\Sysprep.zip
#endregion

#region update Archive
$CompressArg.Path = 'C:\Windows\system32\calc.exe'
Compress-Archive @CompressArg

$CompressArg.Add('Update',$true)
Compress-Archive @CompressArg
#endregion

#region peak in zip file using .net 4.5+ class directly
[IO.Compression.ZipFile]::OpenRead('C:\Sysprep.zip').Entries.Name
#you can contribute new function at: https://github.com/PowerShell/Microsoft.PowerShell.Archive :-)
#endregion

#region Expand Archive
Expand-Archive -Path C:\Sysprep.zip -DestinationPath C:\Sysprep -Force -Verbose
Get-ChildItem -Path C:\Sysprep -Recurse -Depth 1
#endregion