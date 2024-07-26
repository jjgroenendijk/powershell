param (
    [ValidateSet("install", "uninstall", "run")]
    [string]$action
)

# Script execution preferences
$ProgressPreference = 'SilentlyContinue'                                        # This makes Invoke-Webrequest significantly faster
$PSDefaultParameterValues['*:Verbose'] = $true                                  # Enable verbose output for all cmdlets

# Global variables
$CompanyName = "Company"                                                        # Company name
$SoftwareName = "Software Name"                                                 # Software name
$SoftwareVersion = "1.0.0"                                                      # Software version
$currentTime = "$(Get-Date -format FileDateTimeUniversal)"                      # Current time
$LogDirectory = "$env:programdata\$CompanyName\LOG"                             # Logging Directory
$LogPath = "$LogDirectory\$SoftwareName $action $currentTime.log"               # Path to log file
$SoftwareRegistryDetection = "HKLM:\SOFTWARE\$CompanyName\$SoftwareName"        # Registry detection path

# Get details of this script
$sourceFilename = $myInvocation.InvocationName                                  # Filename of this script
$sourceContent = get-content -Path $sourceFilename                              # Content of this script
$destinationDirectory = "${env:ProgramData}\$Companyname\Scripts"               # Path to copy this script to
$destinationFilename = $sourceFilename | Split-Path -Leaf                       # Filename of this script
$destinationPath = "$destinationDirectory\$destinationFilename"                 # Path to copy this script to

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

function copyThisScript {
    # Create script directory if it does not exist
    if (-not (Test-Path $destinationDirectory)) {
        New-Item -Path $destinationDirectory -Force -ItemType Directory
    }

    # Copy this script to the script directory if it does not exist
    Set-Content -Path "$destinationPath" -Value $sourceContent -Force
}

function Start-Log {

    if (-not(test-path $LogDirectory)) { New-Item -Path $LogDirectory -ItemType Directory -Force }
    
    Start-Transcript -Path $LogPath -IncludeInvocationHeader -Append

}

function Stop-Log {

    $allLogs = Get-ChildItem -Path $LogDirectory -Include "*.log" -Recurse
    $oldLogs = $allLogs | Where-Object { ($_.LastWriteTime -lt (Get-Date).AddDays(-180)) }
    
    foreach ($oldLog in $oldLogs) { Remove-Item $oldLog }
    
    Stop-Transcript

}

function new-CustomScheduledTask {
    param (
        [Parameter(Mandatory = $true)]
        [string]$SoftwareName,
        [Parameter(Mandatory = $true)]
        [string]$SoftwareVersion,
        [Parameter(Mandatory = $true)]
        [string]$destinationPath,
        [Parameter(Mandatory = $false)]
        [string]$TaskTrigger
    )

    # Register this script as a scheduled task
    $taskName = "$SoftwareName $SoftwareVersion"
    $taskAction = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -NonInteractive -WindowStyle hidden -ExecutionPolicy Bypass -File ""$destinationPath"" -action run"

    # If taskTrigger is not provided, create a new task trigger for execution at logon
    if (($NULL -eq $TaskTrigger) -or ($TaskTrigger -eq "")) {
        Write-Output "Setting task trigger to AtLogOn"
        $taskTrigger2 = New-ScheduledTaskTrigger -AtLogOn
    }

    # Run the scheduled task as the system user
    $principal = New-ScheduledTaskPrincipal -UserID "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount

    # Check if task already exists
    $taskExists = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($taskExists) {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
    }

    # Register the scheduled task
    Register-ScheduledTask -TaskName $taskName -Action $taskAction -Trigger $taskTrigger2 -Principal $principal -TaskPath "\$CompanyName\"
}

Function Remove-CustomScheduledTask {
    param (
        [Parameter(Mandatory = $true)]
        [string]$SoftwareName,
        [Parameter(Mandatory = $true)]
        [string]$SoftwareVersion
    )

    $taskName = "$SoftwareName $SoftwareVersion"
    $taskExists = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($taskExists) {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
    }
}

Function New-RegistryDetection {

    if (-not(Test-Path $SoftwareRegistryDetection)) { New-Item -Path $SoftwareRegistryDetection -Force }

    # Write version to registry
    Set-ItemProperty -Path $SoftwareRegistryDetection -Name "Version" -Value "$Version"
    
    # Write installation date to registry
    Set-ItemProperty -Path $SoftwareRegistryDetection -Name "InstallDate " -Value $(Get-Date -Format FileDateUniversal)

}

Function Remove-RegistryDetection {

    Remove-Item -Path $SoftwareRegistryDetection -Force -Recurse

}

# Run this script in 64-bit mode
Write-Output "Running in mode: $env:PROCESSOR_ARCHITECTURE"

If ($ENV:PROCESSOR_ARCHITEW6432 -eq "AMD64") {
    Try {
        Write-Output "Restarting to 64-bit mode!"
        & "$ENV:WINDIR\SysNative\WindowsPowershell\v1.0\PowerShell.exe" -File $PSCOMMANDPATH @psboundparameters
    }
    Catch {
        Throw "Failed to start $PSCOMMANDPATH"
    }
    Exit
}

# Start Logging
Start-Log

switch ($action) {

    "install" {
    
        Write-Output "Installing $SoftwareName $SoftwareVersion"

        # Copy this script to the script directory
        copyThisScript

        # Register this script as a scheduled task
        new-CustomScheduledTask -SoftwareName $SoftwareName -SoftwareVersion $SoftwareVersion -destinationPath $destinationPath

        # Create registry detection
        New-RegistryDetection

        # Run the scheduled task immediately
        Get-ScheduledTask -TaskName "$SoftwareName $SoftwareVersion" | Start-ScheduledTask

    }

    "run" {
        Write-Output "Running $SoftwareName $SoftwareVersion"

        Get-ScheduledTask -TaskName "$SoftwareName $SoftwareVersion" | Start-ScheduledTask

        # OPTIONAL: Uncomment the following line to uninstall the software after executing this script
        #Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File ""$destinationPath"" -action uninstall"

    }

    "uninstall" {

        Write-Output "Uninstalling $SoftwareName $SoftwareVersion"

        # Remove the scheduled task
        Remove-CustomScheduledTask -SoftwareName $SoftwareName -SoftwareVersion $SoftwareVersion

        # Remove registry detection
        Remove-RegistryDetection

        # Remove the script from the script directory
        Remove-Item -Path $destinationPath -Force -ErrorAction SilentlyContinue

    }

    default {
        Write-Output "Invalid action"
    }


}

# Stop logging
Stop-Log