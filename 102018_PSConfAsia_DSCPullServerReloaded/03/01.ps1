#region UD
Get-Module -Name UniversalDashboard.Community -ListAvailable
# By MVP Adam Driscoll @adamdriscoll
start https://ironmansoftware.com/universal-dashboard
#endregion

#region setup simple landing page
$homePage = New-UDPage -Name home -Content {
    $connection = New-DSCPullServerAdminConnection -SQLServer sql.mshome.net -Database PSCONFASIADSC -Credential ([pscredential]::new('sa',(ConvertTo-SecureString 'Welkom01' -AsPlainText -Force)))
    $headers = @(
        'NodeName',
        'ConfigurationName',
        'AgentId',
        'LastReport',
        'LastStatus',
        'LastOperation',
        'Edit'
    )
    New-UDRow {
        New-UDGrid -Title "Nodes" -Headers $headers -Properties $headers -AutoRefresh -RefreshInterval 3 -Endpoint {
            $registrations = Get-DSCPullServerAdminRegistration -Connection $connection
            $registrations | ForEach-Object -Process {
                $lastReport = Get-DSCPullServerAdminStatusReport -Connection $connection -AgentId $_.AgentId |
                    Sort-Object -Property EndTime -Descending | Select-Object -First 1
                [pscustomobject]@{
                    NodeName = New-UDLink -Text $_.NodeName -Url "/reports/$($_.AgentId)"
                    ConfigurationName = ($_.ConfigurationNames -join ', ')
                    AgentId = $_.AgentId
                    LastReport = New-UDLink -Text $lastReport.EndTime -Url "/nodereport/$($lastReport.JobId)"
                    LastStatus = $lastReport.Status
                    LastOperation = $lastReport.OperationType
                    Edit = New-UDLink -Text 'Edit' -Url "/node/$($_.AgentId)"
                }
            } | Out-UDGridData
        }
    }
}
#endregion

#region setup page to change node configuration name
$nodePage = New-UDPage -Url "/node/:agentid" -Endpoint {
    param($agentid)

    $connection = New-DSCPullServerAdminConnection -SQLServer sql.mshome.net -Database PSCONFASIADSC -Credential ([pscredential]::new('sa',(ConvertTo-SecureString 'Welkom01' -AsPlainText -Force)))
    $node = Get-DSCPullServerAdminRegistration -AgentId $agentid
    New-UDRow {
        New-UDCard -Title "$($node.NodeName) - $($node.AgentId)" -Content {
            New-UDInput -Title "Change ConfigurationName" -Endpoint {
                param($ConfigurationName)
                Set-DSCPullServerAdminRegistration -AgentId $agentid -ConfigurationNames $ConfigurationName -Connection $connection
                New-UDInputAction -RedirectUrl '/home'
            }
        }
    }
}
#endregion

#region setup reports page for specific jobid
$reportPage = New-UDPage -Url "/nodereport/:jobid" -Endpoint {
    param($jobid)

    $connection = New-DSCPullServerAdminConnection -SQLServer sql.mshome.net -Database PSCONFASIADSC -Credential ([pscredential]::new('sa',(ConvertTo-SecureString 'Welkom01' -AsPlainText -Force)))
    $node = Get-DSCPullServerAdminStatusReport -JobId $jobid -Connection $connection
    New-UDRow {
        New-UDTable -Title $node.NodeName -Headers @(' ', ' ') -Endpoint {
            @{
                JobId = $node.JobId
                OperationType = $node.OperationType
                Status = $node.Status
                StartTime = $node.StartTime
                EndTime = $node.EndTime
                StatusData = ($node.StatusData | ConvertTo-Json)
            }.GetEnumerator() | Out-UDTableData -Property @('Name', 'Value')
        }
    }
}
#endregion

#region setup reports page for all reports of node with agentid
$reportsPage = New-UDPage -Url "/reports/:agentid" -Endpoint {
    param($agentid)

    $connection = New-DSCPullServerAdminConnection -SQLServer sql.mshome.net -Database PSCONFASIADSC -Credential ([pscredential]::new('sa',(ConvertTo-SecureString 'Welkom01' -AsPlainText -Force)))
    $reports = Get-DSCPullServerAdminStatusReport -AgentId $agentid -Connection $connection | Sort-Object -Property EndTime -Descending
    New-UDRow {
        New-UDTable -Title $node.NodeName -Headers @(' ', ' ') -Endpoint {
            foreach ($node in $reports) {
                @{
                    JobId = $node.JobId
                    OperationType = $node.OperationType
                    Status = $node.Status
                    StartTime = $node.StartTime
                    EndTime = $node.EndTime
                    StatusData = ($node.StatusData | ConvertTo-Json)
                }.GetEnumerator() | Out-UDTableData -Property @('Name', 'Value')
            }
        }
    }
}
#endregion

#region start dashboard
$dscDashBoard = New-UDDashboard -Title "DSC Pullserver Dashboard" -Pages @(
    $homePage,
    $nodePage,
    $reportPage,
    $reportsPage
)

Start-UDDashboard -Dashboard $dscDashBoard
start http://localhost
#Get-UDDashboard | Stop-UDDashboard
#endregion
