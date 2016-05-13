#Create configuration and handle through LCM
configuration TestMyResource {
    Import-DscResource -ModuleName PSConfEU
    SMBShare MyShare {
        Ensure = 'Present'
        Path = 'c:\myshare'
        Name = 'MyShare'
    }
}
TestMyResource
Start-DscConfiguration -Path .\TestMyResource -Wait -Verbose