$SolutionDir = $DTE.ActiveDocument.Path
Start-Process -FilePath "$SolutionDir\putty.exe" -ArgumentList '-ssh','ben@el201504.westeurope.cloudapp.azure.com'

<# SSH
wget https://github.com/bgelens/EL2015/raw/master/DSCLinux/dsc-1.1.0-466.ssl_100.x64.rpm
wget https://github.com/bgelens/EL2015/raw/master/DSCLinux/omi-1.0.8.ssl_100.x64.rpm
yum -y localinstall omi-1.0.8.ssl_100.x64.rpm
yum -y localinstall dsc-1.1.0-466.ssl_100.x64.rpm
service omiserverd start
#>

#region cim session
$cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @('root', $AzureCred.Password)
$CimOption = New-CimSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck -UseSsl
$CimSession = New-CimSession -ComputerName el201504.westeurope.cloudapp.azure.com -SessionOption $CimOption -Port 5986 -Credential $cred -Authentication Basic
Get-CimInstance -CimSession $CimSession -ClassName OMI_Identify -Namespace root/omi | select OperatingSystem,ProductName,ProductVersionString
#endregion cim session

Copy-Item -Path $SolutionDir\DscMetaConfigs\localhost.meta.mof -Destination $SolutionDir\DscMetaConfigs\el201504.westeurope.cloudapp.azure.com.meta.mof
#bug in newest win10 build :(
#Set-DscLocalConfigurationManager -CimSession $CimSession -Path $SolutionDir\DscMetaConfigs -Verbose

#show local config instead
Get-Content $SolutionDir\DscMetaConfigs\el201504.westeurope.cloudapp.azure.com.meta.mof | Set-Clipboard
#copy and save using VI
#Navigate to /opt/microsoft/dsc/Scripts and run SetDscLocalConfigurationManager
Get-DscLocalConfigurationManager -CimSession $CimSession | % configurationdownloadmanagers

#show no website
start microsoft-edge:http://el201504.westeurope.cloudapp.azure.com

#region Linux 
#Compile Configuration
Configuration NginX {

    Import-DSCResource -Module NX

    node FrontEnd {
        nxPackage EPEL {
            Ensure = 'Present'
            Name = 'epel-release'
            PackageManager = 'Yum'
        }

        nxPackage NginX {
            Ensure = 'Present'
            Name = 'nginx'
            PackageManager = 'Yum'
            DependsOn = '[nxPackage]EPEL'
        }

        nxFile MyCoolWebPage {
            DestinationPath = '/usr/share/nginx/html/index.html'
            Contents = '<center><H1>Hello Experts Live! This node is managed by OMS Automation DSC :-)</H1></center>
<center><img src="http://expertslive.azurewebsites.net/wp-content/uploads/2015/06/Experts_Live_website_logo.png"></center>'
            Force = $true
            DependsOn = '[nxPackage]NginX'
        }
        
        nxService NginXService {
            Name = 'nginx'
            Controller = 'systemd'
            Enabled = $true
            State = 'Running'
            DependsOn = '[nxFile]MyCoolWebPage'
        }
    }
}
NginX -OutputPath $SolutionDir

#Import AA DSC
$AAAccount | Import-AzureRmAutomationDscNodeConfiguration -Path $SolutionDir\FrontEnd.mof -ConfigurationName 'NginX' -Force
$AAACcount | Get-AzureRmAutomationDscNodeConfiguration

#Assign and converge
$Node = $AAAccount | Get-AzureRmAutomationDscNode -Name EL201504
$AAAccount | Set-AzureRmAutomationDscNode -Id $Node.Id -NodeConfigurationName "NginX.FrontEnd" -Force

Update-DscConfiguration -CimSession $CimSession -Wait -Verbose

$Node | Get-AzureRmAutomationDscNode
#endregion Linux config

start microsoft-edge:http://el201504.westeurope.cloudapp.azure.com