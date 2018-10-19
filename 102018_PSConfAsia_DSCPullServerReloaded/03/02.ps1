#region add new configuration to pull server
$sqlsession | Enter-PSSession

configuration PSConfAsia {
    Import-DscResource -ModuleName PSDesiredStateConfiguration -ModuleVersion 1.1

    Node PSConfAsia {
        File MySuperFile {
            Ensure = 'Present'
            DestinationPath = 'C:\Windows\Temp\MySuperFile.txt'
            Contents = 'PSCONFASIA ROCKS!!!'
        }
    }
}

PSConfAsia -OutputPath 'C:\pullserver\Configuration'
New-DscChecksum -Path 'C:\pullserver\Configuration\PSConfAsia.mof' -Force

Exit-PSSession
#endregion

#region pull new configuration
$lcmsession | Enter-PSSession

# first update via web portal
Update-DscConfiguration -Wait -Verbose
cat C:\Windows\Temp\MySuperFile.txt
#endregion
