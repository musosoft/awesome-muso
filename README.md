
# Awesome muso

Curated list of tools I'm using, step by step right after installation of OS

## Windows tools
- [install Ninite](https://ninite.com/) - Easiest way to Install apps of choice e.g. Chrome, Steam, Skype, etc.
- [install TCUP](https://tcup.eu/) - Total Commander Ultima Prime is advanced TC with a lots of apps and tools.

### Development
- [install Chocolatey](https://chocolatey.org/install) - Package manager for Windows.
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
```

- [install nvm](https://github.com/coreybutler/nvm-windows) - A node.js version management utility for Windows.
```powershell
choco install nvm
```

- [install Terminal](https://github.com/microsoft/terminal/blob/master/README.md) - New Windows Terminal.
```powershell
choco install microsoft-windows-terminal
```

- [install SourceTree](https://www.sourcetreeapp.com) - Nice Git Client.
```powershell
choco install sourcetree
```

- [install Sublime Text](https://www.sublimetext.com) - Text editor.
```powershell
choco install sublimetext3
```
Optional: copy `~` directory to your `%userprofile%`

- [install FiraCode font](https://github.com/tonsky/FiraCode/wiki/Sublimetext-Instructions) - Better readability font for Development.
```powershell
choco install firacode
```