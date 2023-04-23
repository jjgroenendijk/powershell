<#

    J.J. Groenendijk
    23-04-2023

    Script for hands on Autopilot enrollment.
    Useful for systems that have escaped the automatic enrollment.

#>

# Define variables for automated enrollment and assignment in Azure AD
$AutoPilotConfig = @{
    TenantID = "example"
    AppID = "example"
    AppSecret = "example"
    GroupTag = "Ring1"
    AssignedUser = Read-Host "Please enter the UPN for the assigned user"
}

# Install Nuget package provider if it's not installed.
$packageProvider = Get-PackageProvider NuGet -ErrorAction Ignore
if (!($packageProvider))
{
    Install-PackageProvider -Name "NuGet" -Force
}

# Install latest AutoPilot script if it's not installed.
$scriptCheck = Get-InstalledScript -Name Get-WindowsAutopilotInfo
if (!($scriptCheck))
{
Install-Script -Name Get-WindowsAutopilotInfo -Force
}

# Execute Autopilot enrollment, wait for profile and user assignment and then reboot.
Get-WindowsAutopilotInfo -Online @AutoPilotConfig -Assign -Reboot