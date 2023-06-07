
# Awesome muso

Curated list of tools I'm using, installed step by step right after installation of Windows 11 OS from Windows Terminal (run as Administrator).

```powershell
# Unrestrict execution of scripts in PowerShell
Set-ExecutionPolicy unrestricted

# ChrisTitusTech tool - disable mouse acceleration, enable numlock
irm christitus.com/win | iex

# Sophia script - run if official MS setup iso was used to debloat
irm script.sophi.app | iex

# Optimizer tool - run if some other system tweaks are needed
iwr ((irm api.github.com/repos/hellzerg/optimizer/releases/latest | % assets | % browser_download_url)) -OutFile Optimizer.exe; & .\Optimizer.exe

# Chocolatey package manager
irm community.chocolatey.org/install.ps1 | iex
choco feature enable -n allowGlobalConfirmation
choco feature enable -n allowEmptyChecksums

# Install software
choco install googlechrome 7zip vlc powertoys winscp rufus sharex vmware-workstation-player

# Setup CLI tools
choco install bind-toolsonly micro

# Setup Dev tools
choco install git nodejs python composer visualstudio2022buildtools
cp private\.gitconfig ~
cp -Recurse private\.ssh ~
.\private\remotes.ps1

# Setup CopyQ
choco install copyq
cp public\copyq-commands.ini $env:APPDATA\copyq

# Setup PowerShell
choco install pwsh microsoft-windows-terminal nerd-fonts-firacode oh-my-posh
cp public\powerlevel10k_monokai.omp.json ~\Documents\PowerShell
cp public\Microsoft.PowerShell_profile.ps1 ~\Documents\PowerShell
Unblock-File ~\Documents\PowerShell\Microsoft.PowerShell_profile.ps1
Install-Module -Name PowerShellAI

# Setup VS Code
choco install firacode vscode
cp private\sftp\ ~\Documents

# Setup Entertainment
choco install steam battle.net discord jdownloader qbittorrent stremio

# (Optional) Edit and backup PowerShell command history
code (Get-PSReadlineOption).HistorySavePath
```

To install Windows Subsystem for Linux follow https://github.com/musosoft/awesome-muso/blob/master/install-WSL.md
