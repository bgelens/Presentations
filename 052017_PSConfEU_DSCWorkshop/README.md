# PSConfEU DSC Introduction Workshop

## Run on Azure
If you have an Azure subscription or you have just signed up for a trial subscription, you can deploy a practice lab for this workshop on Azure. 

All you need to do is, just click on the below Deploy to Azure button and enter a resource group name, administrator username and password. 

[![Deploy to Azure](http://azuredeploy.net/deploybutton.png)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Frchaganti%2FPSConfEU2017%2Fmaster%2FWS1-DSCOverview%2Fdsclab.json)

This template deploys three VMs as shown in this picture.
![](http://i.imgur.com/oMA2neF.png)

After the VMs are provisioned, all [demoscripts](https://github.com/rchaganti/PSConfEU2017/tree/master/WS1-DSCOverview/DEMOScripts) for the workshop will be available in C:\DemoScripts folder.

S16-DC (domain controller for this environment), will be the jumpbox through which other VMs can be access via PowerShell remoting, RDP, and so on. 

## Run on Hyper-V
If you have portable USB media to spare, please download the files and bring them with you to the workshop so we can help others who haven't yet preparred!

To follow along on your local Hyper-V implementation you need:
* Setup a NAT VM Switch ([Howto](https://docs.microsoft.com/en-us/virtualization/hyper-v-on-windows/user-guide/setup-nat-network)) and use network **172.22.176.0/20 (255.255.240.0)**
* If you are not capable of running a NAT VM Switch on your machine, create a private or internal VM Switch instead. Some little demo's won't apply to you.
* Get Downloads from:
    * Images (Images are not available anymore. If you still want to test out, create 3 patches images. Server 2016 with UI, Server 2016 Core and Server 2012R2 Core)
    * [Resources](https://psconfeu.blob.core.windows.net/demo/DSCResources.zip)
    * [Demo Files](https://psconfeu.blob.core.windows.net/demo/DemoScripts.zip)
* Extract Images to a location and put the zips for the Resources and Demo files in that location
* Download the [LabPrep scrip](https://raw.githubusercontent.com/rchaganti/PSConfEU2017/master/WS1-DSCOverview/LabPrep.ps1) and adjust the variables where applicable
    ```powershell
    $vhdPath = 'path where you extracted the images' #this is the same directory where the Resources and Demo zip files should be
    $2016 = Join-Path -Path $vhdPath -ChildPath 'SysPrep.vhdx'
    $2016Core = Join-Path -Path $vhdPath -ChildPath 'SysPrepCore2016.vhdx'
    $2012Core = Join-Path -Path $vhdPath -ChildPath 'SysPrep2012R2.vhdx'
    $switchName = 'nat'
    $GateWay = '172.22.176.1'
    $DCVMName = 'S16-DC'
    $Password = 'Welkom01'
    $CIDR = '172.22.176.20{0}/20'
    $DCCIDR = $CIDR -f '0'
    $Member2016Name = 'S16-01'
    $Member2012Name = 'S12R2-01'
    ```
* Run the LabPrep script.
    * It will create 3 Generation 2 VMs with 2 vCPUs each. 
        * The first will have 3GB static memory assigned
        * The others will have 2GB dynamic memory assinged with 768MB as lower limit
        * The specifications can be adjusted if your hardware is less (or more) capable.
        ``` powershell
        New-DemoVM -ParentVhd $2016 -ComputerName $DCVMName -CIDR $DCCIDR -Memory 3GB -CPU 2 -DNSServer '8.8.8.8'
        New-DemoVM -ParentVhd $2016Core -ComputerName $Member2016Name -CIDR ($CIDR -f '1') -Memory 2GB -CPU 2 -DNSServer $DCCIDR.Split('/')[0] -Member
        New-DemoVM -ParentVhd $2012Core -ComputerName $Member2012Name -CIDR ($CIDR -f '2') -Memory 2GB -CPU 2 -DNSServer $DCCIDR.Split('/')[0] -Member
        ```
* Wait until all VMs have a domain logon capability. The servers will be done when they do.
