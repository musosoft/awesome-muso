
# Awesome muso

Curated list of tools I'm using, installed step by step right after installation of Windows 11 OS from Windows Terminal (run as Administrator).

```powershell
# Unrestrict execution of scripts in PowerShell
Set-ExecutionPolicy unrestricted

# ChrisTitusTech tool 
irm christitus.com/win | iex

# Sophia script
irm script.sophi.app | iex

# Optimizer tool
iwr ((irm api.github.com/repos/hellzerg/optimizer/releases/latest | % assets | % browser_download_url)) -OutFile Optimizer.exe; & .\Optimizer.exe

# Chocolatey package manager
irm community.chocolatey.org/install.ps1 | iex
choco feature enable -n allowGlobalConfirmation
choco feature enable -n allowEmptyChecksums

# Install software
choco install googlechrome 7zip vlc powertoys winscp vmware-workstation-player rufus sharex

# Setup CLI tools
choco install bind-toolsonly dig micro

# Setup Dev tools
choco install git nodejs python composer visualstudio2022buildtools
cp private\.gitconfig ~
cp private\.ssh\ ~\.ssh
.\private\remotes.ps1

# Setup CopyQ
choco install copyq
cp public\copyq-commands.ini %AppData%\copyq

# Setup PowerShell
choco install pwsh microsoft-windows-terminal nerd-fonts-firacode oh-my-posh
cp public\powerlevel10k_monokai.omp.json ~\Documents\PowerShell
cp public\Microsoft.PowerShell_profile.ps1 ~\Documents\PowerShell
Install-Module -Name PowerShellAI

# Setup VS Code
choco install firacode vscode-insiders
cp private\sftp\ ~\Documents

# Setup Entertainment
choco install steam battle.net discord jdownloader qbittorrent stremio

# (Optional) Edit and backup PowerShell command history
code (Get-PSReadlineOption).HistorySavePath
```

To install Windows Subsystem for Linux follow https://github.com/musosoft/awesome-muso/blob/master/install-WSL.md
