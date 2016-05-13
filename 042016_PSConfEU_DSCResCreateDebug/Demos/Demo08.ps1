$SourceDir = Split-Path -Path $psISE.CurrentFile.FullPath -Parent
$ModuleDir = New-Item -Path 'C:\Program Files\WindowsPowerShell\Modules' -Name 'PSConfEUClass' -ItemType Directory
Copy-Item -Path $SourceDir\Demo09.ps1 -Destination "$($ModuleDir.PSPath)\PSConfEUClass.psm1"
New-ModuleManifest -Path "$($ModuleDir.PSPath)\PSConfEUClass.psd1" `
                   -Guid ([system.guid]::NewGuid().guid) `
                   -Author 'BGelens' `
                   -RootModule 'PSConfEUClass.psm1' `
                   -DscResourcesToExport '*'

Copy-Item -ToSession $pssession -Path ((Get-Module PSConfEUClass -ListAvailable).Path | 
    Split-Path -Parent) -Destination 'C:\Program Files\WindowsPowerShell\Modules' -Recurse -Container

configuration ReverseIt {
    Import-DscResource -ModuleName PSConfEUClass
    node 10.10.10.2 {
        PSConfEUDemo neBsneleG {
            Name = 'Ben Gelens'
        }
    }
}
ReverseIt
Enable-DscDebug -BreakAll -CimSession $cimsession
Start-DscConfiguration .\ReverseIt -Verbose -Wait -CimSession $cimsession

Enter-PSSession $pssession
psedit "$($using:ModuleDir.PSPath)\PSConfEUClass.psm1"
Exit-PSSession