$vhdPath = 'C:\Users\Public\Documents\Hyper-V\Virtual hard disks'
$2016 = Join-Path -Path $vhdPath -ChildPath 'SysPrep.vhdx'
$2016Core = Join-Path -Path $vhdPath -ChildPath 'SysPrepCore2016.vhdx'
$2012Core = Join-Path -Path $vhdPath -ChildPath 'SysPrep2012R2.vhdx'
$switchName = 'nat'
$GateWay = '172.22.176.1'
$DCVMName = 'S16-DC'
$Password = 'Welkom01'
$CIDR = '172.22.176.20{0}/20'
$DCCIDR = $CIDR -f '0'
$Member2016Name = 'S16-01'
$Member2012Name = 'S12R2-01'

#region unattend.xml
function New-UnAttendXML {
    param (
        $ComputerName,
        $CIDR,
        $GateWay,
        $Password,
        $DNSServer
    )
$XML = @'
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="specialize">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <ComputerName>#COMPUTERNAME#</ComputerName>
        </component>
        <component name="Microsoft-Windows-TCPIP" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <Interfaces>
                <Interface wcm:action="add">
                    <Ipv4Settings>
                        <DhcpEnabled>false</DhcpEnabled>
                    </Ipv4Settings>
                    <UnicastIpAddresses>
                        <IpAddress wcm:action="add" wcm:keyValue="1">#CIDR#</IpAddress>
                    </UnicastIpAddresses>
                    <Identifier>Ethernet</Identifier>
                    <Routes>
                        <Route wcm:action="add">
                            <Prefix>0.0.0.0/0</Prefix>
                            <NextHopAddress>#GATEWAY#</NextHopAddress>
                            <Identifier>0</Identifier>
                        </Route>
                    </Routes>
                </Interface>
            </Interfaces>
        </component>
        <component name="Microsoft-Windows-DNS-Client" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <Interfaces>
                <Interface wcm:action="add">
                    <DNSServerSearchOrder>
                        <IpAddress wcm:action="add" wcm:keyValue="0">#DNSSERVER#</IpAddress>
                    </DNSServerSearchOrder>
                    <Identifier>Ethernet</Identifier>
                </Interface>
            </Interfaces>
        </component>
    </settings>
    <settings pass="oobeSystem">
        <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <InputLocale>en-US</InputLocale>
            <SystemLocale>en-US</SystemLocale>
            <UserLocale>en-US</UserLocale>
            <UILanguage>en-US</UILanguage>
        </component>
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <OOBE>
                <SkipMachineOOBE>true</SkipMachineOOBE>
                <SkipUserOOBE>true</SkipUserOOBE>
            </OOBE>
            <TimeZone>W. Europe Standard Time</TimeZone>
            <UserAccounts>
                <AdministratorPassword>
                    <Value>#PASSWORD#</Value>
                    <PlainText>True</PlainText>
                </AdministratorPassword>
            </UserAccounts>
        </component>
    </settings>
    <cpi:offlineImage cpi:source="catalog://lpt-beng/c$users/beng/desktop/psconfeu/dsc resource/supportfiles/install_windows server 2016 technical preview 4 serverdatacenter.clg" xmlns:cpi="urn:schemas-microsoft-com:cpi" />
</unattend>
'@
    $XML = $XML.Replace('#CIDR#',$CIDR)
    $XML = $XML.Replace('#PASSWORD#',$Password)
    $XML = $XML.Replace('#COMPUTERNAME#',$ComputerName)
    $XML = $XML.Replace('#GATEWAY#',$GateWay)
    $XML = $XML.Replace('#DNSSERVER#',$DNSServer)
    $XML
}
#endregion

#region dc script
function New-DCScript {
"
[DscLocalConfigurationManager()]
configuration LCM {
    Settings {
        RebootNodeIfNeeded = `$true
        ActionAfterReboot = 'ContinueConfiguration'
        DebugMode = 'ForceModuleImport'
    }
}

LCM
Set-DscLocalConfigurationManager .\LCM -Force

`$ConfigData = @{
    AllNodes = @(
        @{
            NodeName = 'localhost'
            PSDscAllowPlainTextPassword = `$true
        }
    )
}

`$Cred = [pscredential]::new('Cloud\Administrator',(ConvertTo-SecureString $Password -AsPlainText -Force))

configuration PDC {
    param (
        `$Credential
    )
    Import-DscResource -ModuleName PSDesiredStateConfiguration -ModuleVersion 1.1
    Import-DscResource -ModuleName xActiveDirectory

    Node localhost {
        Script DisableFirewall {
            GetScript = {
                @{
                    GetScript = `$GetScript
                    SetScript = `$SetScript
                    TestScript = `$TestScript
                    Result = -not('True' -in (Get-NetFirewallProfile -All).Enabled)
                }
            }

            SetScript = {
                Set-NetFirewallProfile -All -Enabled False -Verbose
            }

            TestScript = {
                `$Status = -not('True' -in (Get-NetFirewallProfile -All).Enabled)
                `$Status -eq `$True
            }
        }

        WindowsFeature ADDSInstall {
            Ensure = 'Present'
            Name = 'AD-Domain-Services'
        }

        WindowsFeature ADDSTools {
            Ensure = 'Present'
            Name = 'RSAT-ADDS'
            IncludeAllSubFeature = `$true
        }

        xADDomain FirstDC {
            DomainName = 'cloud.lab'
            DomainAdministratorCredential = `$Credential
            SafemodeAdministratorPassword = `$Credential
            DomainNetbiosName = 'cloud'
            DependsOn = '[WindowsFeature]ADDSInstall'
        }
        Script RemoveDSCImplementation {
            GetScript = {
                return @{
                    TestScript = `$TestScript
                    GetScript = `$GetScript
                    SetScript = `$SetScript
                }
            }
            SetScript = {
                `$scriptblock = {
                    Start-Sleep -Seconds 30
                    Get-PSHostProcessInfo | 
                        Where-Object -FilterScript { `$_.AppDomainName -eq 'DscPsPluginWkr_AppDomain'} | 
                            Foreach-Object -Process { `$_.ProcessId | Stop-Process -Force}
                    Clear-Content -Path `"`$env:windir\system32\Configuration\DSCEngineCache.mof`"
                    Clear-Content -Path `"`$env:windir\system32\Configuration\DSCStatusHistory.mof`"
                    Remove-Item -Path `"`$env:windir\System32\Configuration\ConfigurationStatus\*`" -Force
                    Remove-Item -Path `"`$env:windir\System32\Configuration\*.mof`" -Force
                    Remove-Item -Path `"`$env:windir\System32\Configuration\*.mof.checksum`" -Force
                    @(
                        'Microsoft-Windows-DSC/Admin',
                        'Microsoft-Windows-DSC/Operational'
                    ) | ForEach-Object -Process {
                        [System.Diagnostics.Eventing.Reader.EventLogSession]::GlobalSession.ClearLog(`$_)
                    }
                    Get-DscResource | Where-Object -FilterScript {
                        `$_.ModuleName -ne 'PSDesiredStateConfiguration' -and `$_.ModuleName -ne `$null -and `$_.ModuleName -ne 'PackageManagement'
                    } | Select-Object -ExpandProperty ModuleName -Unique | ForEach-Object -Process {
                        Get-Module -Name `$_ -ListAvailable | ForEach-Object -Process {
                            Remove-Item -Path (Split-Path `$_.ModuleBase) -Recurse -Force
                        }
                    }
                    Restart-Computer -Force
                }
                start-process `$pshome\powershell.exe -ArgumentList `"-Command ```"&{`$(`$scriptblock.ToString())}```"`"
            }
            TestScript = {
                `$false
            }
            DependsOn = '[xADDomain]FirstDC'
        }
    }
}

PDC -ConfigurationData `$ConfigData -Credential `$Cred
Start-DscConfiguration .\PDC -Force
"
}
#endregion

#region member script
function New-MemberScript {
"
[DscLocalConfigurationManager()]
configuration LCM {
    Settings {
        RebootNodeIfNeeded = `$true
        ActionAfterReboot = 'ContinueConfiguration'
        DebugMode = 'ForceModuleImport'
    }
}

LCM
Set-DscLocalConfigurationManager .\LCM -Force

`$ConfigData = @{
    AllNodes = @(
        @{
            NodeName = 'localhost'
            PSDscAllowPlainTextPassword = `$true
        }
    )
}

`$Cred = [pscredential]::new('Cloud\Administrator',(ConvertTo-SecureString $Password -AsPlainText -Force))

configuration Member {
    param (
        `$Credential,
        `$DNSServer
    )
    Import-DscResource -ModuleName PSDesiredStateConfiguration -ModuleVersion 1.1
    Import-DscResource -ModuleName xActiveDirectory
    Import-DscResource -ModuleName xComputerManagement
    Import-DscResource -ModuleName xNetworking

    Node localhost {
        Script DisableFirewall {
            GetScript = {
                @{
                    GetScript = `$GetScript
                    SetScript = `$SetScript
                    TestScript = `$TestScript
                    Result = -not('True' -in (Get-NetFirewallProfile -All).Enabled)
                }
            }

            SetScript = {
                Set-NetFirewallProfile -All -Enabled False -Verbose
            }

            TestScript = {
                `$Status = -not('True' -in (Get-NetFirewallProfile -All).Enabled)
                `$Status -eq `$True
            }
        }

        xDNSServerAddress DCDNS {
            InterfaceAlias = 'Ethernet'
            Address = `$DNSServer
            AddressFamily = 'IPv4'
            Validate = `$false
        }

        xWaitForADDomain DscForestWait {
            DomainName = 'cloud.lab'
            DomainUserCredential = `$Credential
            RetryCount = 15
            DependsOn = '[xDNSServerAddress]DCDNS'
        }

        xComputer Rename {
            Name =  `$env:ComputerName
            DomainName = 'cloud.lab'
            Credential = `$Credential
            DependsOn = '[xWaitForADDomain]DscForestWait'
        }
        Script RemoveDSCImplementation {
            GetScript = {
                return @{
                    TestScript = `$TestScript
                    GetScript = `$GetScript
                    SetScript = `$SetScript
                }
            }
            SetScript = {
                `$scriptblock = {
                    Start-Sleep -Seconds 30
                    Get-PSHostProcessInfo | 
                        Where-Object -FilterScript { `$_.AppDomainName -eq 'DscPsPluginWkr_AppDomain'} | 
                            Foreach-Object -Process { `$_.ProcessId | Stop-Process -Force}
                    Clear-Content -Path `"`$env:windir\system32\Configuration\DSCEngineCache.mof`"
                    Clear-Content -Path `"`$env:windir\system32\Configuration\DSCStatusHistory.mof`"
                    Remove-Item -Path `"`$env:windir\System32\Configuration\ConfigurationStatus\*`" -Force
                    Remove-Item -Path `"`$env:windir\System32\Configuration\*.mof`" -Force
                    Remove-Item -Path `"`$env:windir\System32\Configuration\*.mof.checksum`" -Force
                    @(
                        'Microsoft-Windows-DSC/Admin',
                        'Microsoft-Windows-DSC/Operational'
                    ) | ForEach-Object -Process {
                        [System.Diagnostics.Eventing.Reader.EventLogSession]::GlobalSession.ClearLog(`$_)
                    }
                    Get-DscResource | Where-Object -FilterScript {
                        `$_.ModuleName -ne 'PSDesiredStateConfiguration' -and `$_.ModuleName -ne `$null -and `$_.ModuleName -ne 'PackageManagement'
                    } | Select-Object -ExpandProperty ModuleName -Unique | ForEach-Object -Process {
                        Get-Module -Name `$_ -ListAvailable | ForEach-Object -Process {
                            Remove-Item -Path (Split-Path `$_.ModuleBase) -Recurse -Force
                        }
                    }
                    Restart-Computer -Force
                }
                start-process `$pshome\powershell.exe -ArgumentList `"-Command ```"&{`$(`$scriptblock.ToString())}```"`"
            }
            TestScript = {
                `$false
            }
            DependsOn = '[xComputer]Rename'
        }
    }
}

Member -ConfigurationData `$ConfigData -Credential `$Cred -DNSServer $($DCCIDR.Split('/')[0])
Start-DscConfiguration .\Member -Force

"
}
#endregion

#region vm
function New-DemoVM {
    param (
        $ParentVhd,
        $ComputerName,
        $CIDR,
        $Memory,
        $CPU,
        $DNSServer,
        [Switch] $Member
    )
    $DiffPath = Join-Path -Path $VHDPath -ChildPath "$ComputerName.vhdx"
    $null = New-VHD -ParentPath $ParentVhd -Path $DiffPath -Differencing
    $Mount = Mount-VHD -Path $DiffPath -Passthru
    $DriveLetter = ($Mount | Get-Disk | Get-Partition | Where-Object { $_.DriveLetter -and $_.size -gt 1gb}).DriveLetter
    $Unattend = New-UnAttendXML -ComputerName $ComputerName -Password $Password -CIDR $CIDR -GateWay $GateWay -DNSServer $DNSServer
    $null = New-Item -Path $DriveLetter`:\unattend.xml -Value $Unattend -ItemType File -Force
    Copy-Item -Path $vhdPath\DSCResources.zip -Destination "$DriveLetter`:\"
    Expand-Archive -Path $vhdPath\DSCResources.zip -DestinationPath "$DriveLetter`:\Program Files\WindowsPowerShell\Modules"
    Expand-Archive -Path $vhdPath\DemoScripts.zip -DestinationPath "$DriveLetter`:\"
    if (-not $Member) {
        New-DCScript | Out-File $DriveLetter`:\Windows\Temp\DSCConfig.ps1
    } else {
        New-MemberScript | Out-File $DriveLetter`:\Windows\Temp\DSCConfig.ps1
    }
    $null = New-Item $DriveLetter`:\Windows\Setup\Scripts\SetupComplete.cmd -Value '%SYSTEMROOT%\System32\WindowsPowerShell\v1.0\powershell.exe -NoLogo -Executionpolicy bypass -NoProfile -Noninteractive -File C:\Windows\Temp\DSCConfig.ps1' -Force
    $Mount | Dismount-VHD
    $VM = New-VM -Name $ComputerName -SwitchName $switchName -Generation 2 -VHDPath $DiffPath -BootDevice VHD
    if (-not $Member) {
        $VM | Set-VMMemory -DynamicMemoryEnabled $false -StartupBytes $Memory
    } else {
        $VM | Set-VMMemory -DynamicMemoryEnabled $true -StartupBytes $Memory -MinimumBytes 768MB
    }
    $VM | Set-VMProcessor -Count $CPU
    $VM | Enable-VMIntegrationService -Name 'Guest Service Interface'
    $VM | Start-VM
}
#endregion

#region create VMs
New-DemoVM -ParentVhd $2016 -ComputerName $DCVMName -CIDR $DCCIDR -Memory 3GB -CPU 2 -DNSServer '8.8.8.8'
New-DemoVM -ParentVhd $2016Core -ComputerName $Member2016Name -CIDR ($CIDR -f '1') -Memory 2GB -CPU 2 -DNSServer $DCCIDR.Split('/')[0] -Member
New-DemoVM -ParentVhd $2012Core -ComputerName $Member2012Name -CIDR ($CIDR -f '2') -Memory 2GB -CPU 2 -DNSServer $DCCIDR.Split('/')[0] -Member
#endregion


#connect with DomainController
vmconnect.exe $env:COMPUTERNAME $DCVMName