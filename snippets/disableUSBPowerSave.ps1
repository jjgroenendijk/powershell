# Devices with power management settings
$powerMgmt = Get-CimInstance -ClassName MSPower_DeviceEnable -Namespace root/WMI
 
# All USB devices
$UsbDevices = Get-CimInstance -ClassName Win32_PnPEntity -Filter 'PNPClass = "USB"'
 
# Disable power management for USB devices
$UsbDevices | ForEach-Object {
    $powerMgmt | Where-Object InstanceName -Like "*$($_.PNPDeviceID)*"
} | Set-CimInstance -Property @{Enable = $false}

# Disable USB selective suspend setting
powercfg /SETACVALUEINDEX SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0
powercfg /SETDCVALUEINDEX SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0​