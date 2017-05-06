# Create Resource
New-xDscResource -ModuleName NetworkingDsc -Name MSFT_LMHost -FriendlyName LMHost -ClassVersion 1.0.0.0 -Path ..\Demo -Property @(
    New-xDscResourceProperty -Name IsSingleInstance -Attribute Key -Type String -ValidateSet 'Yes' -Description "This is a system wide setting and can only be applied once"
    New-xDscResourceProperty -Name Enable -Type Boolean -Attribute Required -Description "This will Enable or Disable LMHost lookup"
)