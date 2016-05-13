#start microsoft-edge:https://github.com/bgelens/EL2015/tree/master/DSCExtOnboardiing

$RG = Get-AzureRmResourceGroup -Name 'EL201503'
$DSCParams = @{
    ResourceGroupName = $RG.ResourceGroupName
    Location = 'West Europe'
    TemplateFile = "$($dte.ActiveDocument.Path)05-AzureDeploy.json"
    Mode = 'Incremental'
    TemplateParameterObject = @{
        vmName = $RG.ResourceGroupName
        modulesUrl = 'https://github.com/bgelens/EL2015/raw/master/DSCExtOnboardiing/UpdateLCMforAAPull.zip'
        configurationFunction = 'UpdateLCMforAAPull.ps1\ConfigureLCMforAAPull'
        registrationKey = $Keys.PrimaryKey
        registrationUrl = $Keys.EndPoint
        nodeConfigurationName = 'CredSSP.AllServers'
    }
}

Test-AzureRmResourceGroupDeployment @DSCParams -Verbose

New-AzureRmResourceGroupDeployment @DSCParams -Force

$node = $AAAccount | Get-AzureRmAutomationDscNode -Name 'EL201503'
$AAAccount | Get-AzureRmAutomationDscNodeReport -NodeId $node.Id