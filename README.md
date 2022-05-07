
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
choco install vlc 7zip googlechrome vscode nodejs stremio steam battle.net qbittorrent firacode git copyq

# Add git and node to path
refreshenv

# Setup Git
git config --global user.name ""
git config --global user.email ""

# (Optional) Edit and backup PowerShell command history
code (Get-PSReadlineOption).HistorySavePath
```

To install Windows Subsystem for Linux follow https://github.com/musosoft/awesome-muso/blob/master/install-WSL.md
