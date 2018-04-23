function Get-DscPullServerReport {
    [cmdletbinding()]
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('NodeName')]
        [string] $Name,

        [Parameter()]
        [datetime] $StartTime,

        [Parameter(Mandatory)]
        [string] $ConnectionString
    )
    process {
        $connection = [System.Data.SqlClient.SqlConnection]::new($ConnectionString)
        $null = $connection.Open()
        $command = $connection.CreateCommand()
        if ($PSBoundParameters.ContainsKey('Name')) {
            if ($Name.ToCharArray() -contains '*') {
                $Name = $Name.Replace('*','%')
            }
            $query = "SELECT * FROM StatusReport Where NodeName like '{0}'" -f $Name
            if ($PSBoundParameters.ContainsKey('StartTime')) {
                $query += " and StartTime >= Convert(datetime, '{0}' )" -f $StartTime.ToString('yyyy-MM-dd HH:mm:ss')
            }
        } else {
            $query = 'SELECT * FROM StatusReport'
            if ($PSBoundParameters.ContainsKey('StartTime')) {
                $query += " Where StartTime >= Convert(datetime, '{0}' )" -f $StartTime.ToString('yyyy-MM-dd HH:mm:ss')
            }
        }
        $command.CommandText = $query
        Write-Verbose -Message "Query: `n $($command.CommandText)"
        $results = $command.ExecuteReader()
        $returnArray = [System.Collections.ArrayList]::new()
        foreach ($result in $results) {
            $table = @{}
            for ($i = 0; $i -lt $result.FieldCount; $i++) {
                $name = $result.GetName($i)
                switch ($name) {
                    { $_ -in 'StatusData', 'Errors'} {
                        $data = (($result[$i] | ConvertFrom-Json) | ConvertFrom-Json)
                    }
                    'AdditionalData' {
                        $data = ($result[$i] | ConvertFrom-Json)
                    }
                    'IPAddress' {
                        $data = $result[$i] -split ','
                    }
                    default {
                        $data = $result[$i]
                    }
                }
                [void] $table.Add($name, $data)
            }
            $null = $returnArray.Add($table)
        }
        $returnArray.ForEach{[pscustomobject]$_}
        $connection.Close()
        $connection.Dispose()
    }
}

function Get-DscPullServerRegistration {
    [cmdletbinding()]
    param (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Alias('NodeName')]
        [string] $Name,

        [Parameter(Mandatory)]
        [string] $ConnectionString
    )
    process {
        $connection = [System.Data.SqlClient.SqlConnection]::new($ConnectionString)
        $null = $connection.Open()
        $command = $connection.CreateCommand()
        if ($PSBoundParameters.ContainsKey('Name')) {
            if ($Name.ToCharArray() -contains '*') {
                $Name = $Name.Replace('*','%')
            }
            $command.CommandText = "SELECT * FROM RegistrationData Where NodeName like '{0}'" -f $Name
        } else {
            $command.CommandText = 'SELECT * FROM RegistrationData'
        }
        Write-Verbose -Message "Query: `n $($command.CommandText)"
        $results = $command.ExecuteReader()
        $returnArray = [System.Collections.ArrayList]::new()
        foreach ($result in $results) {
            $table = @{}
            for ($i = 0; $i -lt $result.FieldCount; $i++) {
                $name = $result.GetName($i)
                switch ($name) {
                    'ConfigurationNames' {
                        $data = ($result[$i] | ConvertFrom-Json)
                    }
                    'IPAddress' {
                        $data = $result[$i] -Split ','
                    }
                    default {
                        $data = $result[$i]
                    }
                }
                [void] $table.Add($name, $data)
            }
            $null = $returnArray.Add($table)
        }
        $returnArray.ForEach{[pscustomobject]$_}
        $connection.Close()
        $connection.Dispose()
    }
}

function Set-DscPullServerNodeConfiguration {
    [cmdletbinding()]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('NodeName')]
        [string] $Name,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $ConfigurationName,

        [Parameter(Mandatory)]
        [string] $ConnectionString
    )
    process {
        $connection = [System.Data.SqlClient.SqlConnection]::new($ConnectionString)
        $null = $connection.Open()
        $command = $connection.CreateCommand()
        $query = "update RegistrationData set ConfigurationNames = '[ `"{0}`" ]' where NodeName = '{1}'" -f $ConfigurationName, $Name
        $command.CommandText = $query
        Write-Verbose -Message "Query: `n $($command.CommandText)"
        $command.ExecuteNonQuery()
        $connection.Close()
        $connection.Dispose()
    }
}
