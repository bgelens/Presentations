break

#region move to normal PS Host
if ($host.Name -eq 'Visual Studio Code Host') {
    Write-Warning -Message 'ctrl + shift + t'
}
Remove-Module -Name PSReadLine
#endregion

#region start demo
$passwordFile = Get-Content .\password.json | ConvertFrom-Json
$chefclientCred = [pscredential]::new($passwordFile.UserName, ($passwordFile.Password | ConvertTo-SecureString -AsPlainText -Force))
$session = New-PSSession -ComputerName chefclient.mshome.net -Credential $chefclientCred
Enter-PSSession -Session $session
#endregion

#region dsc_resource
Get-Content C:\opscode\chef\embedded\lib\ruby\gems\2.4.0\gems\chef-13.7.16-universal-mingw32\lib\chef\provider\dsc_resource.rb #169 WMFv5+ only
(Get-Content C:\opscode\chef\embedded\lib\ruby\gems\2.4.0\gems\chef-13.7.16-universal-mingw32\lib\chef\provider\dsc_resource.rb)[168]
#endregion

#region simple example
@'
dsc_resource 'whoami' do
  resource :script
  module_name 'PSDesiredStateConfiguration'
  module_version '1.1'
  property :GetScript, '@{}'
  property :TestScript, <<-EOH
    Write-Verbose -Message "Executing TestScript"
    $false
  EOH
  property :SetScript, <<-EOH
    Write-Verbose -Message "Executing SetScript"
    Write-Verbose -Message "Running as: $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)"
  EOH
  property :PsDscRunAsCredential, ps_credential('Administrator', 'Welkom01')
end
'@ | Out-File .\dscscript01.rb -Encoding utf8 -Force
# chef-client --local-mode .\dscscript01.rb

# Get-DscConfigurationStatus
# Get-DscConfiguration
#endregion

#region custom resource
# in case of bad internet
Copy-Item ~\Documents\DockerDsc 'C:\Program Files\WindowsPowerShell\Modules' -Recurse

#container feature already installed to save time
Get-WindowsFeature -Name Containers

# FIRST RUN, Talk during!

@'
powershell_package 'dockerdsc'

dsc_resource 'containersfeature' do
    resource :WindowsFeature
    module_name 'PSDesiredStateConfiguration'
    module_version '1.1'
    property :Ensure, 'Present'
    property :Name, 'Containers'
    reboot_action :reboot_now
end

dsc_resource 'dockerbin' do
    resource :archive
    module_name 'PSDesiredStateConfiguration'
    module_version '1.1'
    property :ensure, 'Present'
    property :path, "C:\\Windows\\TEMP\\docker.zip"
    property :destination, "C:\\Program Files"
end

dsc_resource 'dockerenv' do
    resource :Environment
    module_name 'PSDesiredStateConfiguration'
    module_version '1.1'
    property :Path, true
    property :Name, 'Path'
    property :Value, "C:\\Program Files\\Docker"
end

dsc_resource 'dockersvcregister' do
    resource :DockerService
    module_name 'DockerDsc'
    module_version '0.0.0.2'
    property :Ensure, 'Present'
    property :Path, "C:\\Program Files\\Docker"
end

windows_service 'Docker' do
    action :start
    startup_type :automatic
end
'@ | Out-File .\dscscript03.rb -Encoding utf8 -Force

chef-client --local-mode .\dscscript03.rb

$env:Path = [environment]::GetEnvironmentVariable('Path', [System.EnvironmentVariableTarget]::Machine)
docker info
#endregion

#region notifications
# Update chef config and have it restart service
# Bad practice!!!! use TLS port 2376 in prod

# FIRST RUN, Talk during!
@'
windows_service 'Docker' do
    action :start
    startup_type :automatic
end

dockerconfig = 'C:\ProgramData\docker\config\daemon.json'

dsc_resource 'daemonconf' do
    resource :File
    module_name 'PSDesiredStateConfiguration'
    module_version '1.1'
    property :DestinationPath, "#{dockerconfig}"
    property :Contents, <<-EOH
{
  "hosts": ["tcp://0.0.0.0:2375"]
}
    EOH
    property :Ensure, 'Present'
    notifies :run, 'powershell_script[changeEncoding]', :immediately
    notifies :restart, 'windows_service[Docker]', :immediately
end

powershell_script 'changeEncoding' do
    code '(Get-Content -Encoding UTF8 $env:dockerconfig) | Out-File -Encoding ascii $env:dockerconfig'
    action :nothing
    environment ({'dockerconfig' => "#{dockerconfig}"})
end
'@ | Out-File .\dscscript04.rb -Encoding utf8 -Force
chef-client --local-mode .\dscscript04.rb

docker info # will fail

[environment]::SetEnvironmentVariable('DOCKER_HOST', 'tcp://0.0.0.0:2375', [System.EnvironmentVariableTarget]::Machine)
$env:DOCKER_HOST = [environment]::GetEnvironmentVariable('DOCKER_HOST', [System.EnvironmentVariableTarget]::Machine)
docker info
#endregion
