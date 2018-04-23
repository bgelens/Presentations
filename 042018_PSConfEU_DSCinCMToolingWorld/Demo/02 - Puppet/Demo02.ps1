break

#region move to normal PS Host
if ($host.Name -eq 'Visual Studio Code Host') {
    Write-Warning -Message 'ctrl + shift + t'
}
Remove-Module -Name PSReadLine
#endregion

#region start demo
$passwordFile = Get-Content .\password.json | ConvertFrom-Json
$puppetclientCred = [pscredential]::new($passwordFile.UserName, ($passwordFile.Password | ConvertTo-SecureString -AsPlainText -Force))
$session = New-PSSession -ComputerName puppetclient.mshome.net -Credential $puppetclientCred
Enter-PSSession -Session $session
#endregion

#region multiple resources, dependencies and notifications

# if bad internet
Copy-Item C:\Users\Administrator\Documents\DockerDsc -Destination 'C:\Program Files\WindowsPowerShell\Modules' -Recurse

# RUN FIRST, Explain during!!

@'
dsc { 'dockerdsc' :
    dsc_resource_name   => 'script',
    dsc_resource_module => {
        name    => 'PSDesiredStateConfiguration',
        version => '1.1'
    },
    dsc_resource_properties  => {
        getscript => '
            @{}
        ',
        setscript => '
            Write-Verbose -Message "Executing SetScript"
            Install-Module -Name dockerdsc -Force
        ',
        testscript => '
            Write-Verbose -Message "Executing TestScript"
            if ($null -eq (Get-Module -ListAvailable -Name dockerdsc)) {
                $false
            } else {
                $true
            }
        ',
    },
}

dsc { 'containersfeature' :
    dsc_resource_name   => 'WindowsFeature',
    dsc_resource_module => {
        name    => 'PSDesiredStateConfiguration',
        version => '1.1'
    },
    dsc_resource_properties  => {
        ensure => 'present',
        name => 'Containers'
    },
}

reboot { 'dsc_reboot' :
    message => 'DSC has requested a reboot',
    when => 'pending'
}

dsc { 'dockerbin' :
    dsc_resource_name   => 'archive',
    dsc_resource_module => {
        name    => 'PSDesiredStateConfiguration',
        version => '1.1'
    },
    dsc_resource_properties  => {
        ensure => 'present',
        path => 'C:\\Windows\\TEMP\\docker.zip',
        destination => 'C:\\Program Files'
    },
}

dsc { 'dockerenv' :
    dsc_resource_name   => 'Environment',
    dsc_resource_module => {
        name    => 'PSDesiredStateConfiguration',
        version => '1.1'
    },
    dsc_resource_properties  => {
        path => true,
        name => 'Path',
        value => 'C:\\Program Files\\Docker'
    },
}

dsc { 'dockersvcregister' :
    dsc_resource_name   => 'DockerService',
    dsc_resource_module => {
        name    => 'DockerDsc',
        version => '0.0.0.2'
    },
    dsc_resource_properties  => {
        ensure => 'Present',
        path => 'C:\\Program Files\\Docker'
    },
    require => [
        Dsc['containersfeature'],
        Dsc['dockerdsc'],
        Dsc['dockerbin']
    ],
}

Service { 'docker' :
    ensure => 'running',
    enable => true,
    require => Dsc['dockersvcregister'],
}

File { ['C:\\ProgramData\\docker', 'C:\\ProgramData\\docker\\config'] :
    ensure => 'directory',
}

File { 'C:\\ProgramData\\docker\\config\\daemon.json' :
    content => '{
    "hosts": ["tcp://0.0.0.0:2375"]
    }',
    notify => Service['docker'],
    require => [
        File['C:\\ProgramData\\docker'],
        File['C:\\ProgramData\\docker\\config'],
        Dsc['dockersvcregister'],
    ]
}
'@ | Out-File .\multires.pp -Encoding ascii -Force

# not there yet
Get-Service -Name Docker

puppet apply .\multires.pp

$env:Path = [environment]::GetEnvironmentVariable('Path', [System.EnvironmentVariableTarget]::Machine)
[environment]::SetEnvironmentVariable('DOCKER_HOST', 'tcp://0.0.0.0:2375', [System.EnvironmentVariableTarget]::Machine)
$env:DOCKER_HOST = [environment]::GetEnvironmentVariable('DOCKER_HOST', [System.EnvironmentVariableTarget]::Machine)
docker info
#endregion

#region cleanup a little bit
Stop-Service docker
& 'C:\Program Files\docker\dockerd.exe' --unregister-service
Remove-Item -Path 'C:\Program Files\docker' -Recurse -Force
Remove-Item -Path C:\ProgramData\docker -Recurse -Force
puppet module uninstall puppetlabs-dsc_lite
puppet module uninstall puppetlabs-reboot
# Uninstall-Module -Name dockerdsc -Force
#endregion
