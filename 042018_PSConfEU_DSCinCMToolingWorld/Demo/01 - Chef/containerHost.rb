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
  property :path, 'C:\\Windows\\TEMP\\docker.zip'
  property :destination, 'C:\\Program Files'
end

dsc_resource 'dockerenv' do
  resource :Environment
  module_name 'PSDesiredStateConfiguration'
  module_version '1.1'
  property :Path, true
  property :Name, 'Path'
  property :Value, 'C:\\Program Files\\Docker'
end

dsc_resource 'dockersvcregister' do
  resource :DockerService
  module_name 'DockerDsc'
  module_version '0.0.0.2'
  property :Ensure, 'Present'
  property :Path, 'C:\\Program Files\\Docker'
end

windows_service 'Docker' do
  action :start
  startup_type :automatic
end
