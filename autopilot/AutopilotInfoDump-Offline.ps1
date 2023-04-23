Function OK-Continue {
    $Shell = New-Object -ComObject "WScript.Shell"
    $Button = $Shell.Popup("Autopilot info captured!", 0, "Finished", 0)
}

$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition

$packageProvider = Get-PackageProvider NuGet -ErrorAction Ignore
if (!($packageProvider))
{
    Install-PackageProvider -Name "NuGet" -Force
}

$scriptCheck = Get-InstalledScript -Name Get-WindowsAutopilotInfo
if (!($scriptCheck))
{
Install-Script -Name Get-WindowsAutopilotInfo -Force
}

Get-WindowsAutopilotInfo -OutputFile "$scriptPath\AutopilotDevices.csv" -Append

OK-Continue