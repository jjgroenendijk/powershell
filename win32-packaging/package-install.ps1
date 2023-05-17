<#

    Setup:		Install script for portable software in .IntuneWin format
    Author:		J.J. Groenendijk
    Date:		17-05-2023

#>

# Define software name and version
$SoftwareName = "Name"
$SoftwareVersion = "1.1.1"
$SoftwareExecutable = "Executable.exe"

# Construct destination folder in format: "C:\Program Files\NAME (VERSION)"
$DestinationPath = "$($env:ProgramFiles)\$($SoftwareName) ($SoftwareVersion)"

# Function for checking and creating destination folder
Function Set-Directory
{
    # Check if destination folder exists. Create folder if necessary
    if (-not(Test-Path -Path $DestinationPath))
    {
        Write-Output "Destination path does not exist."

        # Create destination folder
        New-Item -ItemType Directory -Path $DestinationPath

        Write-Output "Created destination path."
    }
}

# Function for copying all folder content to destination folder
Function Copy-Application
{
    Write-Output "Starting copy of application folder to $DestinationPath"

    # Copy folder contents to earlier defined destination folder
    Copy-Item -Path ".\*" -Recurse -Destination "$DestinationPath" -Force

    Write-Output "Copy of application is done"
}

# Function for setting a registry key in HKLM.
Function Set-RegistryDetection
{
    # Define the path of the registry key
    $SoftwareRegistryPath = "HKLM:\Software\BDR\$($SoftwareName)"

    # Check if key already exists
    if (-not(Test-Path $SoftwareRegistryPath))
    {
        Write-Output "Creating registry key"

        # Create key in registry
        New-Item -Path "HKLM:\Software\BDR\" -Name "$($SoftwareName)"

        Write-Output "Setting software version $($SoftwareVersion) in registry"

        # Set version as a registry value
        New-ItemProperty -Path "HKLM:\Software\BDR\$($SoftwareName)" -Name "Version" -Value "$SoftwareVersion"

        Write-Output "Done setting registry"
    }
}

# Function for creating a desktop and start menu shortcut
Function Create-Shortcuts
{
    # Define the location of the start menu shortcut in public profile
    $StartMenuShortcut = "$([Environment]::GetFolderPath('CommonStartMenu'))\programs\$($SoftwareName) ($SoftwareVersion).lnk"

    # Check if Start menu shortcut already exists
    If (-Not(Test-Path -PathType Leaf -Path $StartMenuShortcut))
    {
        Write-Output "No start menu shortcut detected. Creating shortcut"

        # Create shortcut
        $WshShell = New-Object -comObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut($StartMenuShortcut)
        $Shortcut.TargetPath = "$($DestinationPath)\$($SoftwareExecutable)"
        $Shortcut.Save()
    }

    #Define the location of the desktop shortcut location in public profile
    $DesktopShortcut = "$([Environment]::GetFolderPath('CommonDesktopDirectory'))\$($SoftwareName) ($SoftwareVersion).lnk"

    # Check if desktop shortcut already exists.
    If (-Not(Test-Path -PathType Leaf -Path $DesktopShortcut))
    {
        Write-Output "No desktop shortcut detected. Creating shortcut"

        # Create shortcut
        $WshShell = New-Object -comObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut($DesktopShortcut)
        $Shortcut.TargetPath = "$($DestinationPath)\$($SoftwareExecutable)"
        $Shortcut.Save()
    }

}

# Execute functions

Set-Directory

Copy-Application

Set-RegistryDetection

Create-Shortcuts