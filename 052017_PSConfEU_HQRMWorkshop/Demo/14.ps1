Start-Process microsoft-edge:https://github.com/PowerShell/DscResources/tree/master/DscResource.Template

wget -Uri https://raw.githubusercontent.com/PowerShell/DscResources/master/DscResource.Template/appveyor.yml -OutFile .\NetworkingDsc\appveyor.yml
wget -Uri https://raw.githubusercontent.com/PowerShell/DscResources/master/DscResource.Template/README.md -OutFile .\NetworkingDsc\README.md

# setup appveyor integration on GitHub
psedit .\NetworkingDsc\appveyor.yml

psedit .\NetworkingDsc\README.md #include appveyor badge

New-Item -Path .\NetworkingDsc\.gitignore -Value "DSCResource.Tests`r`n.vscode`r`n"

psedit .\NetworkingDsc\NetworkingDsc.psd1

# push and have appveyor run
git push -u origin dev