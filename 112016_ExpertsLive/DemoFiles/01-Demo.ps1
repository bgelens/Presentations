#check if already a resource?
Find-Module -Tag dsc -Name *docker* -Repository psgallery

#no resource, what now?
#latest docker daemon available here:
#https://master.dockerproject.org/windows/amd64/
#predownloaded and placed in c:\program files\docker
Get-ChildItem 'C:\Program Files\docker'

#install docker as a service?
& 'C:\Program Files\docker\dockerd.exe' --help
& 'C:\Program Files\docker\dockerd.exe' --register-service

#remove docker as a service?
& 'C:\Program Files\docker\dockerd.exe' --unregister-service

#region configuration
configuration dockerd {
    script DockerService {
        GetScript = {
            $result = if (Get-Service -Name Docker -ErrorAction SilentlyContinue) {'Service Present'} else {'Service Absent'}
            return @{
                GetScript = $GetScript
                SetScript = $SetScript
                TestScript = $TestScript
                Result = $Result
            }
        }
        SetScript = {
            & 'C:\Program Files\docker\dockerd.exe' --register-service
        }
        TestScript = {
            if (Get-Service -Name Docker -ErrorAction SilentlyContinue) {
                return $true
            } else {
                return $false
            }
        }
    }
}
#endregion

#implement
#dockerd
#Start-DscConfiguration -Path .\dockerd -Wait -Verbose -Force
