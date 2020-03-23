<#
  Ternary Operator
  https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_operators?view=powershell-7#ternary-operator--if-true--if-false

  $true ? 'true' : 'false'
#>
#region ternary
# how we are used to something similar
if ($IsLinux) {
  'yes'
} else {
  'no'
}

# how we can use ternary
$IsLinux ? 'yes' : 'no'

# in case you want execution, add parentheses
$IsLinux ? 'yes' : (Write-Warning 'no')

# example for object creation in the old days
function Test-ConditionIsTrue { $true }

$Ensure = 'Absent'
if (Test-ConditionIsTrue) {
  $Ensure = 'Present'
}

[pscustomobject]@{
  Ensure = $Ensure
}

# now with ternary!

[pscustomobject]@{
  Ensure = (Test-ConditionIsTrue) ? 'Present' : 'Absent'
}

# write multi line is also supported
[pscustomobject]@{
  Ensure = (Test-ConditionIsTrue) ?
  'Present' :
  'Absent'
}
#endregion

<#
  Chain Operators
  https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_pipeline_chain_operators?view=powershell-7

  &&
  ||
#>
#region chain
# execute right hand when left fails $? = $false
$item = Get-Item ./doesnotexist || New-Item ./doesnotexist
$item

# execute right hand when left success $? = $true
brew update && brew upgrade
#endregion

<#
  Null conditional operators for coalescing and assignment
  https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_operators?view=powershell-7#null-coalescing-operator-
  https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_operators?view=powershell-7#null-coalescing-assignment-operator-

  ??
  ??=
#>
#region null conditional
# how we are used to it
if ($null -eq $myVariable) {
  'cast value'
} else {
  $myVariable
}

# how we can do it now

# myvariable is null, "cast value" is returned
$myVariable ?? 'cast value'

$myVariable = 'already set value'
# myvariable is not null, so current value is returned and right hand side is not evaluated
$myVariable ?? 'cast value'

# with assignment, how we are used to it
$myVariable2 = if ($null -eq $myVariable2) {
  'some value'
}

$myVariable2 ??= 'some value'

# common pattern
$rg = Get-AzResourceGroup -Name myRg -ErrorAction SilentlyContinue
if ($null -eq $rg) {
  $rg = New-AzResourceGroup -Name myRg -Location westeurope
}

# now in 2 lines
$rg = Get-AzResourceGroup -Name myRg -ErrorAction SilentlyContinue
$rg ??= New-AzResourceGroup -Name myRg -Location westeurope
#endregion