# Test templates
Start-Process microsoft-edge:https://github.com/PowerShell/DscResources/blob/master/Tests.Template/

# Add unit test
wget -Uri https://raw.githubusercontent.com/PowerShell/DscResources/master/Tests.Template/unit_template.ps1 -OutFile .\NetworkingDsc\Tests\Unit\MSFT_LMHost.Tests.ps1
psedit .\NetworkingDsc\Tests\Unit\MSFT_LMHost.Tests.ps1