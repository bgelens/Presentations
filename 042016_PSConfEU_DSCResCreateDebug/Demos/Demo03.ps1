#import module and run Get/Set/Test-TargetResource in session. Usefull for Unit testing but runs under your credentials not system

$TestArgs = @{
    Ensure = 'Present'
    Path = 'c:\myshare'
    Name = 'MyShare'
}


Get-ChildItem -Path (Get-DscResource -Module PSConfEU).ParentPath -Filter *.psm1 | %{Import-Module $_.FullName -Verbose}
Test-TargetResource @TestArgs -Verbose