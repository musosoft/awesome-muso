
# Awesome muso

Curated list of tools I'm using, step by step right after installation of OS

## Windows tools
- [install Ninite](https://ninite.com/) - Easiest way to Install apps of choice e.g. Chrome, Steam, Skype, etc.
- [install TCUP](https://tcup.eu/) - Total Commander Ultima Prime is advanced TC with a lots of apps and tools.

### Development
- [install nvm](https://github.com/coreybutler/nvm-windows) - A node.js version management utility for Windows.
- [install Chocolatey](https://chocolatey.org/install) - Package manager for Windows.
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
```
- [install Terminal](https://github.com/microsoft/terminal/blob/master/README.md) - New Windows Terminal.
```powershell
choco install microsoft-windows-terminal
```
- [install Sublime Text](https://www.sublimetext.com) - Text editor.
```powershell
choco install sublimetext3
```
- [install Babel for Sublime Text](https://github.com/babel) - A must for ReactJS.
Find it as [**Babel**](https://packagecontrol.io/packages/Babel) through [Package Control](https://packagecontrol.io/).

To set it as the default syntax for a particular extension:
  1. Open a file with that extension,
  2. Select `View` from the menu,
  3. Then `Syntax` `->` `Open all with current extension as...` `->` `Babel` `->` `JavaScript (Babel)`.
  4. Repeat this for each extension (e.g.: `.js` and `.jsx`).

Select `Monokai` from `Preferences` `->` `Color Scheme` `->` `Babel`

- [install FiraCode font](https://github.com/tonsky/FiraCode/wiki/Sublimetext-Instructions) - Better readability font for Development.
```powershell
choco install firacode
```

In Sublime Text:
**Preferences** --> **Settings**

**Add** before `"ignored_packages":`

```
"font_face": "Fira Code Medium",
"font_options":
[
	"subpixel_antialias"
],
```

## REST TO BE UPDATED SOON
