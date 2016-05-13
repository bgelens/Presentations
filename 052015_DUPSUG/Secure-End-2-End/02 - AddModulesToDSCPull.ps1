Find-DscResource | Select-Object -Property ModuleName -Unique | %{
    if (!(Get-Module $_.modulename -ListAvailable)) {
        Install-Module $_.ModuleName -Force
    }
}
$PullServerModulesPath = 'C:\Program Files\WindowsPowerShell\DscService\Modules'
Get-DscResource | Select-Object -Property Module -Unique | %{
    if ($_.Module -match '^[C,X]') {
        $Module = Get-Module $_.Module -ListAvailable
        $Manifest = Test-ModuleManifest $Module.Path
        $ArchiveName = $Manifest.Name + '_' + $Manifest.Version.ToString() + '.zip'
        if (!(Test-Path "$PullServerModulesPath\$ArchiveName")) {
            Write-Verbose -Message "Adding $($Manifest.name) with version $($Manifest.Version.ToString()) to DSC Pull Server Modules repository" -Verbose
            #clear readonly (compress archive seems to break with access denied if this is set)
            Get-ChildItem $Module.ModuleBase -Recurse | %{attrib.exe -R $_.FullName}
            Compress-Archive -Path $module.ModuleBase -DestinationPath "$PullServerModulesPath\$ArchiveName" -Force
            New-DSCCheckSum -Path $PullServerModulesPath\$ArchiveName -Force
        }
    }
}