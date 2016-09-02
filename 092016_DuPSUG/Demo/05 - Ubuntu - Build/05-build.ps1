vmconnect.exe $env:COMPUTERNAME Ubuntu-01
# build custom PS
sudo -su -
cd /home/ben
apt-get install git
git clone --recursive https://github.com/PowerShell/PowerShell.git #already did this because of time...
cd PowerShell
ls
vi ./src/System.Management.Automation/engine/PSVersionInfo.cs #add hashtable entry for PSVersiontable
#s_psVersionTable["CustomShell"] = "BenShell!";
./tools/download.sh
powershell
ipmo ./build.psm1 -Verbose
Start-PSBootstrap -Verbose -Force
Start-PSBuild -Verbose #this will take some time

# why? modify code, build locally, write tests, PR
# why? fun!
# why? Latest commits not merged into packaged release yet

#open in new terminal
$PSVersiontable