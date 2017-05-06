# first test
Describe 'MSFT_LMHost\Test-TargetResource' {

    Context 'Invoking with LMHost currently enabled' {
        Mock -CommandName 'Test-LMHostEnabled' -MockWith {return $true}
        It 'Should return "true" when Enable is set to "true" and current state is "true"' {
            Test-TargetResource -IsSingleInstance 'Yes' -Enable $true | Should Be $true
        }
        It 'Should return "false" when Enable is set to "false" and current state is "true"' {
            Test-TargetResource -IsSingleInstance 'Yes' -Enable $false | Should Be $false
        }
    }

}