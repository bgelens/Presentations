#import module and run Get/Set/Test-TargetResource in session. Usefull for Unit testing but runs under your credentials not system

$TestArgs = @{
    Ensure = 'Present'
    Path = 'C:\Program Files\Docker'
}


Get-ChildItem -Path (Get-DscResource -Module ExpertsLive).ParentPath -Filter *.psm1 | %{Import-Module $_.FullName -Verbose}
Test-TargetResource @TestArgs -Verbose