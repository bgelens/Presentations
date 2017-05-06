#example file
@'
configuration Example
{
    Import-DscResource -ModuleName NetworkingDsc

    node localhost
    {
        LMHost Disable
        {
            IsSingleInstance = 'Yes'
            Enable = $false
        }
    }
}
'@ | Out-File .\NetworkingDsc\Examples\LMHost_Example.ps1 -Encoding utf8
# enable example checking by adding optin
@'
[
    "Common Tests - Validate Example Files"
]
'@ | Out-File .\NetworkingDsc\.MetaTestOptIn.json -Encoding utf8

#create temporary symbolic link to allow example to run correctly
New-Item -Path ~\Documents\WindowsPowerShell\Modules -Name NetworkingDsc -ItemType SymbolicLink -Value (resolve-path .\NetworkingDsc)

# enable example checking in task runner
# run test
# disable in taskrunner again
# remove symbolic link
explorer (Resolve-Path ~\Documents\WindowsPowerShell\Modules\)