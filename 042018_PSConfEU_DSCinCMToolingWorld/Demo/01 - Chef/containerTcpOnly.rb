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
