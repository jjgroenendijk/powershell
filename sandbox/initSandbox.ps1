# Script execution preferences
$ProgressPreference = 'SilentlyContinue'                                        # This makes Invoke-Webrequest significantly faster
$PSDefaultParameterValues['*:Verbose'] = $true                                  # Enable verbose output for all cmdlets
$TempDir = "$env:userprofile\Desktop"

Start-Transcript -Path "$env:userprofile\Desktop\setup.txt" -IncludeInvocationHeader -Append

function initPSModule {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PSModule
    )

    # Check if Nuget package provider is installed
    $nugetCheck = (!(Get-PackageProvider -listavailable -Name Nuget -ErrorAction SilentlyContinue))
    if ($nugetCheck) {
        Write-Output "installing nuget package provider"
        Install-PackageProvider -Name 'Nuget' -scope AllUsers -Force
    }
        
    # Check if PSGallery is trusted
    $repositoryTrustCheck = (Get-PSRepository -Name "PSGallery").InstallationPolicy -ne "Trusted"
    if ($repositoryTrustCheck) {
        Write-Output "Setting PSGallery to trusted"
        Set-PSRepository -Name "PSGallery" -InstallationPolicy "Trusted" -Verbose
    }
    else {
        Write-Output "PSGallery already trusted!"
    }
        
    # Check if the module is installed
    $PSModuleInstallationStatus = Get-InstalledModule -Name $PSModule -ErrorAction SilentlyContinue
    if ($null -eq $PSModuleInstallationStatus) {
        Write-Output "Installing module: $PSModule"
        Install-Module -Name $PSModule -Verbose -AllowClobber -Force -Scope AllUsers
    }
    else {
        Write-Output "PS Module $PSModule already installed!"
    }
        
    # Check if the module is imported
    $PSModuleImportStatus = Get-Module -Name $PSModule -ErrorAction SilentlyContinue
    if ($null -eq $PSModuleImportStatus) {
        Write-Output "Importing module: $PSModule"
        Import-Module $PSModule -Verbose
    }
    else {
        Write-Output "PS Module $PSModule already imported!"
    }
}

initPSModule -PSModule microsoft.winget.client

Repair-WinGetPackageManager -AllUsers -Force -Latest

# Array of winget applications to install
$apps = @(
    "Microsoft.UI.Xaml.2.8",
    "Microsoft.WindowsTerminal",
    "7zip.7zip"
    "Microsoft.VisualStudioCode"
)

# wait for the winget binary to be installed before installing apps
$wingetBinary = (Get-Command winget).Source	

foreach ($app in $apps) {
        Write-Output "Installing $app"
        Start-Process -FilePath $wingetBinary -ArgumentList "install --exact --id $app --accept-package-agreements --accept-source-agreements --silent --scope machine" -NoNewWindow -Wait
}


# User popup to tell the user the script has finished
Add-Type -AssemblyName PresentationFramework
[System.Windows.MessageBox]::Show('Setup complete!', 'Setup', 'OK', 'Information')

Stop-Transcript