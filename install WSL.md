
# Install Windows Subsystem for Linux
wsl --install
shutdown -r -t 00
wsl --set-default-version 2
curl.exe -L -o Ubuntu.appx https://aka.ms/wslubuntu
Add-AppxPackage .\Ubuntu.appx

# Create AppModelUnlock if it doesn't exist, required for enabling Developer Mode
$RegistryKeyPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock"
if (-not(Test-Path -Path $RegistryKeyPath)) {
    New-Item -Path $RegistryKeyPath -ItemType Directory -Force
}

# Add registry value to enable Developer Mode
New-ItemProperty -Path $RegistryKeyPath -Name AllowDevelopmentWithoutDevLicense -PropertyType DWORD -Value 1
