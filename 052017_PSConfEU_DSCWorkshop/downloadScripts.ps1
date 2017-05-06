param (
    [string]$archiveURL
)

#Download from the Github repo
Invoke-WebRequest $archiveURL -OutFile "${env:Temp}\master.zip" -UseBasicParsing

#Extract using .NET. We won't have PS5 cmdlets before DSC extension install on Server 2012 R2
Add-Type -assembly "System.IO.Compression.FileSystem"
[io.compression.zipfile]::ExtractToDirectory("${env:Temp}\master.zip", $env:Temp)

#Move only DemoScripts folder
Move-Item -Path "${env:TEMP}\PSConfEU2017-master\WS1-DSCOverview\DEMOScripts" -Destination C:\ -Force


 