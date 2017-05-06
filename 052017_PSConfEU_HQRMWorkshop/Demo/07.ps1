# test task runner
Start-Process microsoft-edge:https://github.com/PowerShell/vscode-powershell/blob/develop/examples/.vscode/tasks.json
# cmd pallete, configure task runner
@'
{
    // See https://go.microsoft.com/fwlink/?LinkId=733558
    // for the documentation about the tasks.json format
    "version": "0.1.0",
    "command": "${env.windir}\\sysnative\\windowspowershell\\v1.0\\PowerShell.exe",
    "isShellCommand": true,
    "args": [
        "-NoProfile",
        "-ExecutionPolicy",
        "Bypass"
    ],
    "showOutput": "always",
    "tasks": [
        {
            "taskName": "Test",
            "suppressTaskName": true,
            "isTestCommand": true,
            "showOutput": "always",
            "args": [
                "Write-Host 'Invoking Pester...'; Invoke-Pester -PesterOption @{IncludeVSCodeMarker=$true};",
                "Invoke-Command { Write-Host 'Completed Test task in task runner.' }"
            ],
            "problemMatcher": [
                {
                    "owner": "powershell",
                    "fileLocation": [
                        "absolute"
                    ],
                    "severity": "error",
                    "pattern": [
                        {
                            "regexp": "^\\s*(\\[-\\]\\s*.*?)(\\d+)ms\\s*$",
                            "message": 1
                        },
                        {
                            "regexp": "^\\s+at\\s+[^,]+,\\s*(.*?):\\s+line\\s+(\\d+)$",
                            "file": 1,
                            "line": 2
                        }
                    ]
                }
            ]
        }
    ]
}
'@