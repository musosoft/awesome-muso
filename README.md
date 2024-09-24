
# Awesome muso

Curated list of tools I'm using, installed step by step right after installation of Windows 11 OS from Windows Terminal (run as Administrator).

```powershell
irm gg.gg/awesomemuso
```

# Unrestrict execution of scripts in PowerShell

```powershell
Set-ExecutionPolicy unrestricted
```

# ChrisTitusTech wintool - disable mouse acceleration, enable numlock, import json to install apps

```powershell
irm christitus.com/win | iex
```

# Sophia script - run if official MS setup iso was used to remove preinstalled bloatware

```powershell
irm script.sophi.app | iex
```

# Chocolatey package manager

```powershell
irm community.chocolatey.org/install.ps1 | iex
choco feature enable -n allowGlobalConfirmation
choco feature enable -n allowEmptyChecksums
```

# Install software not in CTT wintool

```powershell
choco install bind-toolsonly whois firacode nerd-fonts-firacode adb
```

# Tweak software

```powershell
cp "G:\My Drive\private\.gitconfig" ~
cp -Recurse "G:\My Drive\private\.ssh" ~
."G:\My Drive\private\remotes.ps1"
cp ~\Documents\PowerShell\awesome-muso\public\copyq-commands.ini $env:APPDATA\copyq
cp ~\Documents\PowerShell\awesome-muso\public\powerlevel10k_monokai.omp.json ~\Documents\PowerShell
cp ~\Documents\PowerShell\awesome-muso\public\Microsoft.PowerShell_profile.ps1 ~\Documents\PowerShell
Unblock-File ~\Documents\PowerShell\Microsoft.PowerShell_profile.ps1
."G:\My Drive\private\api.ps1"
cp "G:\My Drive\private\sftp\" ~\Documents
```

# (Optional) Edit and backup PowerShell command history

```powershell
code (Get-PSReadlineOption).HistorySavePath
```
