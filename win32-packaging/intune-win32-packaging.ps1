<#

    J.J. Groenendijk
    05-12-2023
    Package setup.exe to setup.intunewin

    Voer dit uit op Windows 11:
    https://support.microsoft.com/en-us/windows/command-prompt-and-windows-powershell-for-windows-11-6453ce98-da91-476f-8651-5c14d5777c20

#>

# Deze handmatig uitvoeren als scripts uitgeschakeld staan op systeem
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process

# Work from current directory
$workingDirectory = split-path -parent $MyInvocation.MyCommand.Definition

# Controle op nodige folders binnen working directory.
if (!(Test-Path -Path "$workingDirectory\tmp"))
{
    New-Item -ItemType Directory -Path $workingDirectory -Name "in" -Force
    New-Item -ItemType Directory -Path $workingDirectory -Name "out" -Force
    New-Item -ItemType Directory -Path $workingDirectory -Name "tmp" -Force
}

# Check if preptool exists
if (!(test-path -PathType Leaf -Path "$workingDirectory\Microsoft-Win32-Content-Prep-Tool-master\IntuneWinAppUtil.exe"))
{
    # Download Intune Prep tool
    $preptoolURL = "https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool/archive/refs/heads/master.zip"
    $preptoolDest = "$workingDirectory\master.zip"
    Invoke-WebRequest -Uri $preptoolURL -OutFile $preptoolDest

    # Unzip prep tool
    Expand-Archive -Path "$workingDirectory\master.zip" -DestinationPath "$workingDirectory"
    
    # Remove zip file
    Remove-Item -Path "$workingDirectory\master.zip"
}

# Haal alle setups op
$setups = Get-ChildItem -Path "$workingDirectory\in"

# Package alle setups naar een intune formaat
Foreach ($setup in $setups)
{
    # verplaats setup naar tijdelijke folder
    Move-Item -Path "$workingDirectory\in\$setup" -Destination "$workingDirectory\tmp\$setup"
    
    # Geef aan welke setup wordt ingepakt
    write-output "Packaging $($setup)"
    
    # Verwerk setup naar een intune formaat
    Start-Process -FilePath "$workingDirectory\Microsoft-Win32-Content-Prep-Tool-master\IntuneWinAppUtil.exe" -ArgumentList "-c ""$workingDirectory\tmp"" -s ""$setup"" -o ""$workingDirectory\out"""
    
    # Sleep van 1 seconde om race condition te voorkomen
    Start-Sleep -Seconds 1

    # verplaats kopie van setup terug naar in folder
    Move-Item -Path "$workingDirectory\tmp\$setup" -Destination "$workingDirectory\in\$setup"
}
