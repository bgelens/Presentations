Clear-Host
Write-Verbose -Message 'Showing PSVersionTable' -Verbose
$PSVersionTable
Read-Host
Clear-Host
Write-Verbose -Message 'Modules available on Windows Build' -Verbose
Get-Module -ListAvailable | Out-String
Read-Host
Clear-Host
Write-Verbose -Message 'Number of commands' -Verbose
Get-Command | Group-Object -Property CommandType | Out-String
Read-Host
Clear-Host
Write-Verbose -Message 'Simple function' -Verbose
"function foo {'called in a simple function'}"
function foo {'called in a simple function'}
'foo'
foo
Read-Host
Clear-Host
Write-Verbose -Message 'More advanced function' -Verbose
@'
function bar {
    [cmdletbinding()]
    [outputtype([System.String])]
    param (
        [parameter(Mandatory,ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [System.String] $Name
    )
    process {
        Write-Verbose -Message ('Processing {0}' -f $Name)
        "Hello $Name!"
    }
}
'@
function bar {
    [cmdletbinding()]
    [outputtype([System.String])]
    param (
        [parameter(Mandatory,ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [System.String] $Name
    )
    process {
        Write-Verbose -Message ('Processing {0}' -f $Name)
        "Hello $Name!"
    }
}
'bar'
bar
Read-Host
'bar -Name ben'
bar -Name ben
Read-Host
"'DuPSUG','Ben' | bar -Verbose"
'DuPSUG','Ben' | bar -Verbose
Read-Host
Clear-Host
Write-Verbose -Message 'Do While' -Verbose
'do {
    $i++;$i
} while ($i -ne 5)'
do {
    $i++;$i
} while ($i -ne 5)
Read-Host
Clear-Host
Write-Verbose -Message 'for loop' -Verbose
'for ($X= 1;$X -le 5;$X++) {
    $X
}'
for ($X= 1;$X -le 5;$X++) {
    $X
}
Read-Host
Clear-Host
Write-Verbose -Message 'Last one: Classes!' -Verbose
'class Ben {
    [System.String] $Name

    Ben([System.String] $Name) {
        $this.Name = $Name
    }
}'
class Ben {
    [System.String] $Name

    Ben([System.String] $Name) {
        $this.Name = $Name
    }
}
Read-Host
'[Ben]::new'
[Ben]::new
Read-Host
'[Ben]::new("DuPSUG!")'
[Ben]::new('DuPSUG!')
Read-Host
Clear-Host