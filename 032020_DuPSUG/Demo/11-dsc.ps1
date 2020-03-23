# dsc compilation no more need for omi / dsc package
Import-Module -Name PSDesiredStateConfiguration

configuration dsc {
  Import-DscResource -ModuleName PowerShellGet -ModuleVersion 2.2.3

  PSModule PSUnixUtilCompleters {
    Name = 'PSUnixUtilCompleters'
    Ensure = 'Present'
  }
}

dsc