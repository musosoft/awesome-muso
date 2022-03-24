
# Awesome muso

Curated list of tools I'm using, installed step by step right after installation of Windows 11 OS from Windows Terminal (run as Administrator).

```powershell
# Unrestrict execution of scripts in PowerShell
Set-ExecutionPolicy unrestricted

# ChrisTitusTech tool 
iwr -useb https://git.io/JJ8R4 | iex

# Sophia script
irm script.sophi.app | iex

# Optimizer tool
Invoke-Webrequest (Invoke-RestMethod -uri https://api.github.com/repos/hellzerg/optimizer/releases/latest | select -ExpandProperty assets | select -expand browser_download_url) -OutFile Optimizer.exe; & .\Optimizer.exe

# Chocolatey package manager
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
choco feature enable -n allowGlobalConfirmation
choco feature enable -n allowEmptyChecksums

# Install software
choco install vlc 7zip googlechrome vscode nodejs stremio steam battle.net qbittorrent firacode git ditto droidcamclient soundwire

# Add git and node to path
refreshenv

# Setup Git
git config --global user.name ""
git config --global user.email ""

# Install node packages
npm i -g npm-upgrade

# Ultimate Power cfg
powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61

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

# (Optional) Edit and backup PowerShell command history
code (Get-PSReadlineOption).HistorySavePath
```
