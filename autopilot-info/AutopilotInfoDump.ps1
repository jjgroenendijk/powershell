Function OK-Continue {
    $Shell = New-Object -ComObject "WScript.Shell"
    $Button = $Shell.Popup("Autopilot info captured!", 0, "Finished", 0)
}

$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition

Install-PackageProvider -Name "NuGet" -Force
Install-Script -Name Get-WindowsAutopilotInfo -Force
Get-WindowsAutopilotInfo -OutputFile "$scriptPath\AutopilotDevices.csv" -Append

OK-Continue