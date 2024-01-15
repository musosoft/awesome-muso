# Ensure running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Please run this script as an Administrator!"
    break
}

# Function to set Group Policy
function Set-GPRegistryValue {
    param(
        [string]$key,
        [string]$valueName,
        [string]$valueType,
        [string]$valueData
    )

    if (-not (Test-Path $key)) {
        New-Item -Path $key -Force | Out-Null
    }

    Set-ItemProperty -Path $key -Name $valueName -Type $valueType -Value $valueData
}

# Enable driver updates via Windows Update
Set-GPRegistryValue "HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate" "ExcludeWUDriversInQualityUpdate" "Dword" 0

# Set Windows Update to notify for download and auto install
Set-GPRegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" "AUOptions" "Dword" 2

# Refresh Group Policy settings
gpupdate /force

Write-Output "Driver updates are now set to show in Windows Update, but they will not be automatically downloaded."
