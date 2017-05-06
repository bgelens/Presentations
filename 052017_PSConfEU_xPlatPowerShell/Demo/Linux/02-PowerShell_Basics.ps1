$PSVersionTable

$IsLinux
$IsWindows
$IsOSX

Get-Command | more
Get-Process
gps

ls env:
dir env:
Get-ChildItem -Path env:

$env:PSModulePath
$env:PSModulePath.Split(':')
Get-Module -ListAvailable
Find-Module -Tag Linux

#work with Azure
Install-Module -Name AzureRM.NetCore.Preview -Scope CurrentUser -Force
Get-Command -Module AzureRM.Resources.NetCore.Preview
Import-Module AzureRM.NetCore.Preview
Add-AzureRmAccount -TenantId bgelens.nl
Get-AzureRmResourceGroup
Get-AzureRmResource -ResourceGroupName BGAA -ResourceName MyAAAccount
Get-AzureRmADUser -UserPrincipalName ben@bgelens.nl | select *
#New-AzureRmResourceGroupDeployment -TemplateFile

#work with office 365
$O365Credential = Get-Credential -UserName ben@bgelens.nl
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $O365Credential -Authentication Basic -AllowRedirection
#Import-PSSession -Session $Session
Invoke-Command -Session $Session -ScriptBlock {Get-Mailbox}

#work with Linux files
Get-Content -Path /etc/passwd
$import = Import-Csv -Path /etc/passwd -Delimiter ':' -Header Name,Pwd,UID,GUID,Info,Home,Shell
$import
$import | Group-Object -Property Shell
chsh -s /usr/bin/powershell ben
mate-terminal -e "su ben"

#os release
Get-Content -Path /etc/os-release
function Get-OSInfo {
    [cmdletbinding(DefaultParameterSetName='Brief')]
    param (
        [Parameter(ParameterSetName='Full')]
        [switch] $Full
    )
    process {
        $osInfoFull = (Get-Content -Path /etc/os-release).Replace('"','') |
            ConvertFrom-StringData
        if ($PSCmdlet.ParameterSetName -eq 'Brief') {
            $osInfoFull.PRETTY_NAME
        } else {
            $osInfoFull
        }
    }
}

Get-OSInfo
Get-OSInfo -Full

# I want to know about the disks / volumes
Get-Disk
Get-Volume

# Linux command to show disk utilization
df
# sum total
df --total
# human readable
df --total -h
# sort on disk where most space available
bash -c "df -h | tail -n +2 | sort -k 4 -rh | head -1"

# for non Linux folk, this would be a long search on google.
# but now we know, let's make it a bit easier.
function Get-LinuxVolume {
    $result = df -T | tail -n +2
    $result | ForEach-Object -Process {
        $splitresult = $_ -split "\s+"
        [pscustomobject]@{
            FileSystem = $splitresult[0]
            Type = $splitresult[1]
            "1KBlocks" = $splitresult[2]
            Used = $splitresult[3]
            Available = $splitresult[4]
            "Use" = $splitresult[5]
            MountedOn = $splitresult[6]
        }
    }
}
Get-LinuxVolume
Get-LinuxVolume | Sort-Object -Property Available | Select-Object -First 1

# now we have 2 tools, let's put them in a Module
$userModulePath = $env:PSModulePath.Split(':').where{$_.split('/')[1] -eq 'root' -and $_.split('/') -notcontains '.vscode'}
$ModuleDir = New-Item -Path $userModulePath -Name MyTools -ItemType Directory
$psm1 = New-Item -Path $ModuleDir.FullName -ItemType File -Name MyTools.psm1
(Get-Command -Name Get-OSInfo).ScriptBlock.Ast.Extent.Text |
    Out-File $psm1 -Append -Encoding utf8
(Get-Command -Name Get-LinuxVolume).ScriptBlock.Ast.Extent.Text |
    Out-File $psm1 -Append -Encoding utf8
New-ModuleManifest -Path (Join-Path $ModuleDir.FullName 'MyTools.psd1') -RootModule MyTools.psm1 -FunctionsToExport @('Get-OSInfo','Get-LinuxVolume')

# see the module is now available
mate-terminal -e powershell

# working with API SWAPI
wget --header="Content-Type: application/json" http://swapi.co/api -qO- | python -m json.tool
wget --header="Content-Type: application/json" http://swapi.co/api/species -qO- | python -m json.tool

Invoke-RestMethod -Uri http://swapi.co/api
Invoke-RestMethod -Uri http://swapi.co/api/people
(Invoke-RestMethod -Uri http://swapi.co/api/people).results | select name
$vader = (Invoke-RestMethod -Uri http://swapi.co/api/people/?search=vader).results
$vader.starships |%{ iwr -uri $_ | select -expand content | ConvertFrom-Json }

# awesome community contribution Florian Feldhaus
# https://github.com/PowerShell/PowerShell/pull/2006
Invoke-WebRequest -SkipCertificateCheck
Invoke-RestMethod -SkipCertificateCheck 
