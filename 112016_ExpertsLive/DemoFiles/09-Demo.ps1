$SourceDir = Split-Path -Path $psISE.CurrentFile.FullPath -Parent
$ModuleDir = New-Item -Path 'C:\Program Files\WindowsPowerShell\Modules'-Name 'ExpertsLiveClass'-ItemType Directory
Copy-Item -Path $SourceDir\code2.ps1 -Destination "$($ModuleDir.PSPath)\ExpertsLiveClass.psm1" -Force
New-ModuleManifest -Path "$($ModuleDir.PSPath)\ExpertsLiveClass.psd1" `
                   -Guid ([system.guid]::NewGuid().guid) `
                   -Author 'BGelens' `
                   -RootModule 'ExpertsLiveClass.psm1' `
                   -DscResourcesToExport '*'

Copy-Item -ToSession $pssession -Path ((Get-Module ExpertsLiveClass -ListAvailable).Path | 
    Split-Path -Parent) -Destination 'C:\Program Files\WindowsPowerShell\Modules' -Recurse -Container -Force

#parse time error checking
configuration DockerClass {
    Import-DscResource -ModuleName ExpertsLiveClass
    node $nanoip {
        DockerService DockerD {
            Ensure = 'Present'
            Path = 'C:\Program Files\docker\'
        }
    }
}
DockerClass
Enable-DscDebug -BreakAll -CimSession $cimsession
Start-DscConfiguration .\DockerClass -Verbose -Wait -CimSession $cimsession -Force
Disable-DscDebug -CimSession $cimsession