# Add additional folders required
Start-Process 'microsoft-edge:https://github.com/PowerShell/DscResources/blob/master/CONTRIBUTING.md#submitting-a-new-resource-module'

New-Item -Path .\NetworkingDsc -Name Tests -ItemType Directory
New-Item -Path .\NetworkingDsc\Tests -Name Unit -ItemType Directory
New-Item -Path .\NetworkingDsc\Tests -Name Integration -ItemType Directory
New-Item -Path .\NetworkingDsc -Name Examples -ItemType Directory

