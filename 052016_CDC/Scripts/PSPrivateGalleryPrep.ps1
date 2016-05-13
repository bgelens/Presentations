#Download Private Gallery from https://github.com/powershell/psprivategallery
#Extract on WMF5 machine to C:\PSPrivateGallery

#Update Credential files
$GalleryAdminFile = get-content C:\PSPrivateGallery\Configuration\GalleryAdminCredFile.clixml
$Replace = ($GalleryAdminFile | Select-String "password").ToString().Split('">')[3].TrimEnd('</SS')
$Replaced = $GalleryAdminFile.Replace($Replace,(ConvertTo-SecureString -String 'P@ssw0rd!' -AsPlainText -Force|ConvertFrom-SecureString))
$Replaced | Set-Content C:\PSPrivateGallery\Configuration\GalleryAdminCredFile.clixml -Force

$GalleryUserFile = get-content C:\PSPrivateGallery\Configuration\GalleryUserCredFile.clixml
$Replace = ($GalleryUserFile | Select-String "password").ToString().Split('">')[3].TrimEnd('</SS')
$Replaced = $GalleryUserFile.Replace($Replace,(ConvertTo-SecureString -String 'P@ssw0rd!' -AsPlainText -Force|ConvertFrom-SecureString))
$Replaced | Set-Content C:\PSPrivateGallery\Configuration\GalleryUserCredFile.clixml -Force

#Start default config
Start-Process powershell.exe -ArgumentList '-file .\PSPrivateGallery.ps1' -Wait -WorkingDirectory C:\PSPrivateGallery\Configuration
#assert again as sometimes it needs more then 1 run
Start-DscConfiguration -UseExisting -Force -Verbose -Wait
Start-Process powershell.exe -ArgumentList '-file .\PSPrivateGalleryPublish.ps1' -Wait -WorkingDirectory C:\PSPrivateGallery\Configuration
#validate
Get-DscConfigurationStatus -All