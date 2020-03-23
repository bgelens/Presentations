# how we are used to it
$ErrorView = 'NormalView'

8 / 0

function badcode {
  8 / 0
}

badcode

# new!
$ErrorView = 'ConciseView'

8 / 0

badcode

# very nice way to display errors using Get-Error!
Get-Error