#Requires -Version 5.1

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdministrator)) {
    try {
        Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList @(
            '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ('"{0}"' -f $PSCommandPath)
        ) | Out-Null
    } catch {
        [Windows.Forms.MessageBox]::Show("Administrator privileges are required.`r`n$($_.Exception.Message)", 'Gaming Mode') | Out-Null
    }
    return
}

$dataDirectory = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'GamingMode'
$configPath = Join-Path $dataDirectory 'config.json'
$legacyConfigPath = Join-Path ([Environment]::GetFolderPath('ApplicationData')) 'GamingModeConfig.json'
$enterScript = Join-Path $PSScriptRoot 'process-kill-before-gaming.ps1'
$restoreScript = Join-Path $PSScriptRoot 'process-restore-after-gaming.ps1'

function Get-PropertyValues($Object, [string[]]$Names) {
    $values = @()
    foreach ($name in $Names) {
        if ($null -ne $Object -and $null -ne $Object.PSObject.Properties[$name]) {
            $values += @($Object.$name)
        }
    }
    @($values | ForEach-Object { if ($null -ne $_) { ([string]$_).Trim() } } |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Sort-Object -Unique)
}

function Read-Configuration {
    $source = $configPath
    if (-not (Test-Path -LiteralPath $source) -and (Test-Path -LiteralPath $legacyConfigPath)) {
        $source = $legacyConfigPath
    }
    if (-not (Test-Path -LiteralPath $source)) {
        return [ordered]@{ Version = 1; Services = @(); Processes = @(); Tasks = @() }
    }
    try {
        $loaded = Get-Content -LiteralPath $source -Raw | ConvertFrom-Json
        return [ordered]@{
            Version = 1
            Services = @(Get-PropertyValues $loaded @('Services', 'CustomServices'))
            Processes = @(Get-PropertyValues $loaded @('Processes', 'CustomProcesses'))
            Tasks = @(Get-PropertyValues $loaded @('Tasks', 'CustomTasks'))
        }
    } catch {
        [Windows.Forms.MessageBox]::Show("The configuration could not be read. Empty settings will be shown.`r`n$($_.Exception.Message)", 'Gaming Mode') | Out-Null
        return [ordered]@{ Version = 1; Services = @(); Processes = @(); Tasks = @() }
    }
}

function Save-Configuration($Value) {
    if (-not (Test-Path -LiteralPath $dataDirectory)) {
        New-Item -ItemType Directory -Path $dataDirectory -Force | Out-Null
    }
    $temporaryPath = "$configPath.$PID.tmp"
    $Value | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $temporaryPath -Encoding UTF8
    Move-Item -LiteralPath $temporaryPath -Destination $configPath -Force
}

function New-TargetTab([string]$Title, [string[]]$Available, [string[]]$Selected) {
    $page = New-Object Windows.Forms.TabPage
    $page.Text = $Title

    $list = New-Object Windows.Forms.CheckedListBox
    $list.CheckOnClick = $true
    $list.Dock = 'Fill'
    $list.HorizontalScrollbar = $true
    foreach ($item in @($Available + $Selected | Sort-Object -Unique)) {
        if ([string]::IsNullOrWhiteSpace($item)) { continue }
        $index = $list.Items.Add($item)
        $list.SetItemChecked($index, ($Selected -contains $item))
    }

    $editor = New-Object Windows.Forms.Panel
    $editor.Dock = 'Bottom'
    $editor.Height = 42
    $text = New-Object Windows.Forms.TextBox
    $text.Location = New-Object Drawing.Point(8, 10)
    $text.Width = 280
    $text.Anchor = 'Left,Right,Top'
    $add = New-Object Windows.Forms.Button
    $add.Text = 'Add'
    $add.Location = New-Object Drawing.Point(296, 8)
    $add.Width = 70
    $add.Anchor = 'Right,Top'
    $remove = New-Object Windows.Forms.Button
    $remove.Text = 'Remove'
    $remove.Location = New-Object Drawing.Point(372, 8)
    $remove.Width = 75
    $remove.Anchor = 'Right,Top'
    $editor.Controls.AddRange(@($text, $add, $remove))
    $page.Controls.Add($list)
    $page.Controls.Add($editor)

    $add.Add_Click({
        $value = $text.Text.Trim()
        if (-not [string]::IsNullOrWhiteSpace($value)) {
            $existing = $list.Items.IndexOf($value)
            if ($existing -lt 0) { $existing = $list.Items.Add($value) }
            $list.SetItemChecked($existing, $true)
            $text.Clear()
        }
    }.GetNewClosure())
    $remove.Add_Click({
        if ($list.SelectedIndex -ge 0) { $list.Items.RemoveAt($list.SelectedIndex) }
    }.GetNewClosure())

    [pscustomobject]@{ Page = $page; List = $list }
}

$config = Read-Configuration

try { $availableServices = @(Get-Service | Where-Object Status -eq 'Running' | Select-Object -ExpandProperty Name | Sort-Object -Unique) }
catch { $availableServices = @() }

$excludedProcesses = @('Idle', 'System', 'Registry', 'smss', 'csrss', 'wininit', 'services', 'lsass', 'winlogon', 'dwm', 'svchost', 'fontdrvhost', 'Memory Compression', 'powershell', 'pwsh')
try {
    $availableProcesses = @(Get-Process | Where-Object { $excludedProcesses -notcontains $_.Name } |
        Select-Object -ExpandProperty Name | Sort-Object -Unique)
} catch { $availableProcesses = @() }

try {
    $availableTasks = @(Get-ScheduledTask | Where-Object State -eq 'Running' |
        ForEach-Object { "$($_.TaskPath)$($_.TaskName)" } | Sort-Object -Unique)
} catch { $availableTasks = @() }

$form = New-Object Windows.Forms.Form
$form.Text = 'Gaming Mode Configurator'
$form.Size = New-Object Drawing.Size(500, 650)
$form.MinimumSize = New-Object Drawing.Size(420, 420)
$form.StartPosition = 'CenterScreen'

$tabs = New-Object Windows.Forms.TabControl
$tabs.Dock = 'Fill'
$serviceTab = New-TargetTab 'Services' $availableServices $config.Services
$processTab = New-TargetTab 'Processes' $availableProcesses $config.Processes
$taskTab = New-TargetTab 'Scheduled Tasks' $availableTasks $config.Tasks
$tabs.TabPages.AddRange(@($serviceTab.Page, $processTab.Page, $taskTab.Page))

$buttons = New-Object Windows.Forms.FlowLayoutPanel
$buttons.Dock = 'Bottom'
$buttons.Height = 48
$buttons.FlowDirection = 'RightToLeft'
$buttons.Padding = New-Object Windows.Forms.Padding(5)
$saveEnter = New-Object Windows.Forms.Button
$saveEnter.Text = 'Save && Enter'
$saveEnter.Width = 110
$save = New-Object Windows.Forms.Button
$save.Text = 'Save'
$save.Width = 80
$restore = New-Object Windows.Forms.Button
$restore.Text = 'Restore'
$restore.Width = 80
$buttons.Controls.AddRange(@($saveEnter, $save, $restore))
$form.Controls.Add($tabs)
$form.Controls.Add($buttons)

function Save-FromForm {
    $newConfig = [ordered]@{
        Version = 1
        Services = @($serviceTab.List.CheckedItems | ForEach-Object { [string]$_ } | Sort-Object -Unique)
        Processes = @($processTab.List.CheckedItems | ForEach-Object { [string]$_ } | Sort-Object -Unique)
        Tasks = @($taskTab.List.CheckedItems | ForEach-Object { [string]$_ } | Sort-Object -Unique)
    }
    Save-Configuration $newConfig
}

$save.Add_Click({
    try {
        Save-FromForm
        [Windows.Forms.MessageBox]::Show('Configuration saved.', 'Gaming Mode') | Out-Null
    } catch {
        [Windows.Forms.MessageBox]::Show("Configuration was not saved.`r`n$($_.Exception.Message)", 'Gaming Mode') | Out-Null
    }
})
$saveEnter.Add_Click({
    try {
        Save-FromForm
        & $enterScript
        [Windows.Forms.MessageBox]::Show('Gaming Mode command completed. Review the console for warnings.', 'Gaming Mode') | Out-Null
    } catch {
        [Windows.Forms.MessageBox]::Show("Gaming Mode failed.`r`n$($_.Exception.Message)", 'Gaming Mode') | Out-Null
    }
})
$restore.Add_Click({
    try {
        & $restoreScript
        [Windows.Forms.MessageBox]::Show('Restore command completed. Review the console for warnings.', 'Gaming Mode') | Out-Null
    } catch {
        [Windows.Forms.MessageBox]::Show("Restore failed.`r`n$($_.Exception.Message)", 'Gaming Mode') | Out-Null
    }
})

[void]$form.ShowDialog()
