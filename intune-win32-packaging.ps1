<#

    Quick concept for automating a single step of Intune Packaging

#>

# Define working directory.
$workingDirectory = "$env:USERPROFILE\Desktop\Application Prep"

# Create working directory if it doesn't exist
if (!(Test-Path $workingDirectory)) 
{
    # Dit kan wel korter
    New-Item -ItemType Directory -Path $workingDirectory
    New-Item -ItemType Directory -Path $workingDirectory -Name "in"
    New-Item -ItemType Directory -Path $workingDirectory -Name "out"
    New-Item -ItemType Directory -Path $workingDirectory -Name "tmp"
}

# Controleer of git geïnstalleerd is. Installeer indien nodig met WinGet
if (!(git))
{
    Write-Output "Installing Git first"
    winget install git.git
}

# Clone de git repository van Microsoft
Start-Process -FilePath "git" -ArgumentList "clone https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool.git ""$workingDirectory""" 

# Haal alle setups op
$setups = Get-ChildItem -Path "$workingDirectory\in"
Write-Output $setups

# Package alle setups naar een intune formaat
Foreach ($setup in $setups)
{
    Start-Process -FilePath "$workingDirectory\IntuneWinAppUtil.exe" -ArgumentList "-c ""$workingDirectory\in"" -s ""$setup"" -o ""$workingDirectory\out""" -WindowStyle Hidden
}
