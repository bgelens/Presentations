$AAAccountName = 'EL2015AA'

#region Create AA Account
$AARG = New-AzureRmResourceGroup -Name $AAAccountName -Location 'westeurope'
$AAAccount = $AARG | New-AzureRmAutomationAccount -Name $AAAccountName -Plan Free
$AAAccount
#endregion Create AA Account

#region Show AA Keys
$AAAccount | Get-AzureRmAutomationRegistrationInfo -OutVariable Keys
#endregion Show Keys