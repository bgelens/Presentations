<#
  Null Conditional Member Property and Method Access
  https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_operators?view=powershell-7#null-conditional-operators--and-

  Experimental
#>
#region null conditional member / property access
Get-ExperimentalFeature -Name PSNullConditionalOperators

# cannot call method on a null-valued expression
$null.ToString()
${null}?.ToString()

# cannot index into a null array
$null[0]
${null}?[0]
#endregion
