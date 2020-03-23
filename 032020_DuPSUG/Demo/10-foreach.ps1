# normal serial processing
(Measure-Command -Expression {
    1..5 | ForEach-Object -Process {
      $_
      Start-Sleep -Seconds 1
    }
  }).TotalMilliseconds

# parallel processing
(Measure-Command -Expression {
    1..5 | ForEach-Object -Parallel {
      $_
      Start-Sleep -Seconds 1
    }
  }).TotalMilliseconds

# standard uses 5 for Throttlelimit
(Measure-Command -Expression {
    1..10 | ForEach-Object -Parallel {
      $_
      Start-Sleep -Seconds 1
    }
  }).TotalMilliseconds

# can be increased (but be warned, overload can happen)
(Measure-Command -Expression {
    1..10 | ForEach-Object -Parallel {
      $_
      Start-Sleep -Seconds 1
    } -ThrottleLimit 10
  }).TotalMilliseconds

# accessing variables from local session using using modifier
$myVar = 'bla'
1..5 | ForEach-Object -Parallel {
  "$using:myVar + $_"
}
