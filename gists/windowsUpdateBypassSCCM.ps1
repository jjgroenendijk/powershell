function initPSModule {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PSModule
    )

    Write-Output "Initializing PS Module: $PSModule"


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

Stop-Service -Name wuauserv
Remove-Item HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate -Recurse
Start-Service -name wuauserv

initPSModule -PSModule "PSWindowsUpdate"

Add-WUServiceManager -MicrosoftUpdate

Get-WindowsUpdate -AcceptAll -IgnoreReboot -Install -Verbose