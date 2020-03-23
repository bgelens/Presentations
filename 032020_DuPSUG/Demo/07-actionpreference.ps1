# run in terminal app!
function foo {
  param (
    [Parameter(Mandatory)]
    [uint16] $Value1,

    [Parameter(Mandatory)]
    [uint16] $Value2
  )

  Write-Verbose -Message "Devide $Value1 by $Value2"

  $Value1 / $Value2
}

# no problem
foo -Value1 2 -Value2 2

# oops!
foo -Value1 2 -Value2 0

# now we can break at the moment of error. Nice to be able to inspect variables, etc
foo -Value1 2 -Value2 0 -ErrorAction Break

# we can break on any *Preference, no more need to add Wait-Debugger :)
$VerbosePreference = 'Break'
foo -Value1 2 -Value2 1