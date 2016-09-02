$workingdir = Split-Path -Path $psISE.CurrentFile.FullPath -Parent

#region show VM
vmconnect.exe $env:COMPUTERNAME CentOS-01
#endregion

#region Copy RPM to VM
Get-ChildItem -Path $workingdir -Filter *.rpm | ForEach-Object -Process {
    Write-Verbose -Message "Copying file: $($_.BaseName)" -Verbose
    Copy-VMFile -SourcePath $_.FullName -Name CentOS-01 -FileSource Host -DestinationPath /tmp
}
#endregion

#region Install PowerShell
Start-Process bash -ArgumentList '-c tmux'
<#
    ssh ben@172.31.255.240
    sudo yum -y localinstall /tmp/powershell-6.0.0_alpha.9-1.el7.centos.x86_64.rpm
    #dependencies are installed automatically by yum
    powershell

    $PSVersionTable
    Get-Command | more
    Get-Process
    gps

    Get-ChildItem env:
    $env:PSMODULEPATH.Split(':')

    Get-Module -ListAvailable
    Find-Module *netcore* -Verbose
    #Install-Module bugged in this packaged release because of semantic versioning

    New-Item -Path /home/ben/.local/share/powershell/Modules -Name CronTab -ItemType Directory -Force
    Invoke-WebRequest `
        -Uri https://raw.githubusercontent.com/PowerShell/PowerShell/master/demos/crontab/CronTab/CronTab.psm1 `
        -OutFile /home/ben/.local/share/powershell/Modules/CronTab/CronTab.psm1; clear

    Invoke-WebRequest `
        -Uri https://raw.githubusercontent.com/PowerShell/PowerShell/master/demos/crontab/CronTab/CronTab.psd1 `
        -OutFile /home/ben/.local/share/powershell/Modules/CronTab/CronTab.psd1 ; clear

    Invoke-WebRequest `
        -Uri https://raw.githubusercontent.com/PowerShell/PowerShell/master/demos/crontab/CronTab/CronTab.ps1xml `
        -OutFile /home/ben/.local/share/powershell/Modules/CronTab/CronTab.ps1xml; clear

    Get-Module -ListAvailable
    Get-Command -Module CronTab
    New-CronJob -<tab><tab>
    New-CronJob -Command 'ps -aux' -Hour 1
    Get-CronJob
    crontab --help
    crontab -l
    Get-CronJob | Remove-CronJob -WhatIf
    Get-CronJob | Remove-CronJob
    Get-CronJob | Remove-CronJob -Force

    #deal with Linux files
    Get-Content -Path /etc/passwd
    $import = Import-Csv -Path /etc/passwd -Delimiter ':' -Header Name, Pwd, UID, GUID, Info, Home, Shell
    $import | more
    $import | Group-Object -Property Shell

    Get-Content /etc/os-release
    function Get-OSInfo {
        [cmdletbinding(DefaultParameterSetName='Brief')]
        param (
            [Parameter(ParameterSetName='Full')]
            [Switch] $Full
        )
        process {
            $osInfoFull = (Get-Content -Path /etc/os-release).Replace('"','') | ConvertFrom-StringData
            if ($PSCmdlet.ParameterSetName -eq 'Brief') {
                $osInfoFull.PRETTY_NAME
            } else {
                $osInfoFull
            }
        }
    }
    Get-OSInfo
    Get-OSInfo -Full

#>
#endregion
