#show tests
#copy tests over to nano server
Copy-Item -ToSession $pssession -Path C:\Demo\EL_DockerD.Tests.ps1 -Destination 'C:\Program Files\WindowsPowerShell\Modules\ExpertsLive'

#invoke tests
$pssession | Enter-PSSession
cd -Path (Split-Path (Get-Module -Name ExpertsLive -ListAvailable).Path)
Get-ChildItem
Invoke-Pester

#fix last bug
psedit (Get-ChildItem -Path (Get-DscResource -Module ExpertsLive).ParentPath -Filter *.psm1).fullname
Invoke-Pester

Exit-PSSession