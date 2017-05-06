# First we want to compile. Let's use the same configuration as applied locally
configuration EPEL {
    nxPackage EPEL {
        Ensure = 'Present'
        Name = 'epel-release'
        PackageManager = 'Yum'
    }
}

EPEL

# Did not work because windows doesn't know about nxPackage
# Let's fix that
Install-Module -Name nx -Force -Verbose

# Because it's Windows we have to use Import-DscResource keyword
configuration EPEL {
    
    Import-DscResource -ModuleName nx
    
    node 172.22.176.250 {
        nxPackage EPEL {
            Ensure = 'Present'
            Name = 'epel-release'
            PackageManager = 'Yum'
        }
    }
}

# let's try again and enact
EPEL
Start-DscConfiguration .\EPEL -Wait -Verbose -Force

# we will create a cimsession
$CimArgs = @{
    SessionOption = New-CimSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck -UseSsl
    ComputerName = '172.22.176.250'
    Authentication = 'Basic'
    Credential = [pscredential]::new('root',(ConvertTo-SecureString 'Welkom01' -AsPlainText -Force))
}
$CimSession = New-CimSession @CimArgs
$CimSession

# let's see if we can get a cim instance
Get-CimInstance -CimSession $cimsession -Namespace root/omi -ClassName OMI_Identify

# LCM
Get-DscLocalConfigurationManager -CimSession $CimSession

# now let's send the config
Start-DscConfiguration .\EPEL -Wait -Verbose -Force -CimSession $CimSession

# Test
Test-DscConfiguration -CimSession $CimSession

# Get
Get-DscConfiguration -CimSession $CimSession
