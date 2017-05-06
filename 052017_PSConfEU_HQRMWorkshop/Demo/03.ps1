# Get Netadapter config through CIM
Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration

# Filter for IP Enabled adapters
Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration -Filter 'IPEnabled = TRUE'

# LMHostlookup is system wide setting
$CimInstance = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration -Filter 'IPEnabled = TRUE'
$CimInstance | Select-Object -First 1 -Property  *lmhost*
$CimInstance[0].WINSEnableLMHostsLookup

# Change setting through CIM
Get-CimClass -ClassName Win32_NetworkAdapterConfiguration
Get-CimClass -ClassName Win32_NetworkAdapterConfiguration | Select-Object -ExpandProperty CimClassMethods

Get-CimClass -ClassName Win32_NetworkAdapterConfiguration | Select-Object -ExpandProperty CimClassMethods | 
    Where-Object -FilterScript { $_.Name -eq 'EnableWINS'} | Select-Object -ExpandProperty Parameters

# Disable
Invoke-CimMethod -ClassName Win32_NetworkAdapterConfiguration -MethodName EnableWINS -Arguments @{
    WINSEnableLMHostsLookup = $false
}

# Enable
Invoke-CimMethod -ClassName Win32_NetworkAdapterConfiguration -MethodName EnableWINS -Arguments @{
    WINSEnableLMHostsLookup = $true
}

# Return Values
Start-Process 'microsoft-edge:https://msdn.microsoft.com/en-us/library/aa390384(v=vs.85).aspx'