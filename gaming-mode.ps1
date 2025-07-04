#Requires -RunAsAdministrator

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# === Admin Check ===
function Test-Admin {
    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Admin)) {
    Write-Warning "Administrator privileges are required. Attempting to re-launch as admin..."
    $scriptPath = $MyInvocation.MyCommand.Path
    Start-Process PowerShell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs
    exit
}

# === Persistent Storage ===
$configPath = "$env:APPDATA\GamingModeConfig.json"

function Load-Config {
    Write-Host "Loading config from $configPath"
    
    $initialCustomServices = @(
        "AGMService", "CamoService", "RustDesk", "TeamViewer", "Spooler", "SysMain",
        "WSearch", "StiSvc", "StateRepository", "WpnUserService_6a294",
        "CDPUserSvc_6a294", "OneSyncSvc_6a294", "NordUpdateService", "nordvpn-service"
    ) | Get-Unique
    $initialCustomProcesses = @(
        "Vesktop", "Beeper", "PowerToys", "PowerToys.PowerLauncher", "PowerToys.ColorPickerUI",
        "PowerToys.AdvancedPaste", "PowerToys.Peek.UI", "PowerToys.Awake", "PowerToys.FancyZones",
        "PowerToys.CropAndLock", "PowerToys.AlwaysOnTop", "Microsoft.CmdPal.UI", "AMDInstallManager",
        "RustDesk", "TeamViewer", "GoogleDriveFS", "CopyQ", "Code", "thorium", "git",
        "TextInputHost", "SearchHost", "SearchIndexer", "SearchProtocolHost", "explorer",
        "SystemSettings", "StartMenuExperienceHost", "ShellExperienceHost", "ApplicationFrameHost",
        "ShellHost", "taskhostw", "RuntimeBroker", "Adobe Crash Processor", "crashpad_handler",
        "SecurityHealthSystray", "WingetUI", "AdobeNotificationClient", "msedgewebview2",
        "MicrosoftEdgeUpdate", "NordUpdateService", "nordvpn-service", "wslrelay", "wslservice", "vmcompute"
    ) | Get-Unique
    $initialCustomTasks = @(
        "SystemSoundsService", "CacheTask"
    ) | Get-Unique

    $defaultConfig = @{
        Services=@(); Processes=@(); Tasks=@();
        CustomServices=$initialCustomServices;
        CustomProcesses=$initialCustomProcesses;
        CustomTasks=$initialCustomTasks
    }

    if (Test-Path $configPath) {
        try {
            $jsonContent = Get-Content $configPath | ConvertFrom-Json
            Write-Host "Config file found. Merging with defaults for any missing or empty custom lists."

            $loadedConfigHashtable = @{}
            if ($jsonContent -is [System.Management.Automation.PSCustomObject]) {
                $jsonContent.PSObject.Properties | ForEach-Object { $loadedConfigHashtable[$_.Name] = $_.Value }
            } elseif ($jsonContent -is [System.Collections.Hashtable]) {
                $loadedConfigHashtable = $jsonContent
            } else {
                 Write-Warning "Loaded config is not a PSCustomObject or Hashtable. Proceeding with caution."
            }
            
            foreach ($key in @("Services", "Processes", "Tasks")) {
                if (-not $loadedConfigHashtable.ContainsKey($key)) {
                    $loadedConfigHashtable[$key] = @()
                }
            }
            foreach ($key in @("CustomServices", "CustomProcesses", "CustomTasks")) {
                $shouldPopulateWithDefaults = $false
                if (-not $loadedConfigHashtable.ContainsKey($key)) {
                    $shouldPopulateWithDefaults = $true
                } else {
                    $listValue = $loadedConfigHashtable[$key]
                    if ($listValue -eq $null -or ($listValue -is [System.Collections.ICollection] -and $listValue.Count -eq 0)) {
                        $shouldPopulateWithDefaults = $true
                    }
                }

                if ($shouldPopulateWithDefaults) {
                    Write-Host "Populating empty/missing custom list '$key' with defaults."
                    $loadedConfigHashtable[$key] = $defaultConfig[$key]
                }
            }
            return $loadedConfigHashtable
        } catch {
            Write-Host "[ERROR] An error occurred while processing the config file. Initializing with full defaults. Error: $($_.Exception.Message)" -ForegroundColor Red
            return $defaultConfig
        }
    } else {
        Write-Host "No config file found. Starting fresh with defaults."
        return $defaultConfig
    }
}

function Save-Config($config) {
    Write-Host "Saving config to $configPath"
    try {
        $fullConfig = @{
            Services = $config.Services | Get-Unique
            Processes = $config.Processes | Get-Unique
            Tasks = $config.Tasks | Get-Unique
            CustomServices = $config.CustomServices | Get-Unique
            CustomProcesses = $config.CustomProcesses | Get-Unique
            CustomTasks = $config.CustomTasks | Get-Unique
        }
        $fullConfig | ConvertTo-Json -Depth 5 | Set-Content $configPath
    } catch {
        Write-Host "[ERROR] Failed to save config." -ForegroundColor Red
    }
}

$config = Load-Config

# === Live System Scan with Filters ===
$excludedServiceKeywords = @(
    "Windows", "Microsoft", "Defend", "Update", "Firewall", "Security", "TrustedInstaller", "WaaS",
    "System", "Core", "Manager", "Service", "Host", "Broker", "Client", "Server", "Driver",
    "Intel", "NVIDIA", "AMD", "Realtek", "Audio", "Network", "Display", "Input", "Hyper-V", "VMware", "Virtual"
)
$excludedServiceDisplayKeywords = @( 
    "Windows", "Microsoft", "Defender", "Firewall", "Security", "System", "Core", "Manager",
    "Driver", "Intel", "NVIDIA", "AMD", "Realtek", "Audio", "Network", "Display", "Input", "Hyper-V", "VMware", "Virtual"
)
$excludedProcessNames = @(
    "System", "Idle", "svchost", "csrss", "smss", "lsass", "wininit", "winlogon", "services", "dwm",
    "explorer", "taskhostw", "RuntimeBroker", "ctfmon", "conhost", "powershell", "pwsh", "cmd",
    "sihost", "fontdrvhost", "audiodg", "spoolsv", "SearchIndexer", "Registry", "Memory Compression",
    "Secure System", "SystemSettingsBroker", "ApplicationFrameHost", "ShellExperienceHost", "StartMenuExperienceHost",
    "WmiPrvSE", "dllhost", "MsMpEng", "NisSrv", "SecurityHealthService", "SecurityHealthSystray"
)
$excludedTaskPatterns = @(
    "^Microsoft\\Windows",
    "^Microsoft\\Office",
    "^\\Microsoft\\Windows", 
    "Update$", 
    "Updater$", 
    "Intel", "NVIDIA", "AMD", "Realtek", 
    "Adobe Acrobat Update Task", "GoogleUpdateTask", "MicrosoftEdgeUpdateTask"
)
$lowerSystemPaths = @( # Defined once, in lowercase
    "$($env:WINDIR.ToLower())\system32", 
    "$($env:WINDIR.ToLower())\syswow64", 
    "$($env:WINDIR.ToLower())\winsxs"
)

try {
    $availableServices = Get-Service | Where-Object { $_.Status -eq 'Running' } | ForEach-Object {
        $serviceObj = $_
        if (($serviceObj.Name -ilike "*Microsoft*") -or ($serviceObj.Name -ilike "*Windows*") -or `
            ($serviceObj.DisplayName -ilike "*Microsoft*") -or ($serviceObj.DisplayName -ilike "*Windows*")) {
            return $null 
        }
        $serviceCim = Get-CimInstance Win32_Service -Filter "Name='$($serviceObj.Name)'" -ErrorAction SilentlyContinue
        $pathName = $serviceCim.PathName
        if ($pathName) {
            $pathNameLower = ($pathName -replace '"', '').ToLower()
            $isSystemPath = $false
            foreach ($sysPath in $lowerSystemPaths) {
                if ($pathNameLower.StartsWith($sysPath)) {
                    $isSystemPath = $true; break
                }
            }
            if (-not $isSystemPath) { $serviceObj.Name } else { $null }
        } else { $null }
    } | Where-Object {$_ -ne $null} | Sort-Object | Select-Object -First 30
    Write-Host "Filtered services: $($availableServices -join ", ")"
} catch {
    Write-Host "[ERROR] Failed to retrieve services. $($_.Exception.Message)" -ForegroundColor Red
    $availableServices = @()
}

try {
    $availableProcesses = Get-Process | Where-Object {
        $process = $_
        $isExcludedName = $excludedProcessNames -contains $process.Name
        $isSystemPath = $false
        if ($process.Path) {
            [string]$processPathLower = $process.Path.ToLower()
            foreach ($sysPath in $lowerSystemPaths) { # Use $lowerSystemPaths
                if ($processPathLower.StartsWith($sysPath)) {
                    $isSystemPath = $true; break
                }
            }
        } else { 
            $isSystemPath = $true
        }
        (-not $isExcludedName) -and (-not $isSystemPath) -and ($process.Name -match '^[a-zA-Z]')
    } | ForEach-Object { $_.Name } | Sort-Object -Unique | Select-Object -First 30
    Write-Host "Filtered processes: $($availableProcesses -join ", ")"
} catch {
    Write-Host "[ERROR] Failed to retrieve processes. $($_.Exception.Message)" -ForegroundColor Red
    $availableProcesses = @()
}

try {
    $rawTasks = schtasks /query /fo LIST /v | Select-String "^TaskName:\s+(.*)" |
                ForEach-Object { ($_ -replace "^TaskName:\s+", "") -replace "^\\", "" }
    
    $availableTasks = $rawTasks | Where-Object {
        $taskPath = $_
        $isExcluded = $false
        foreach ($pattern in $excludedTaskPatterns) {
            if ($taskPath -match $pattern) {
                $isExcluded = $true; break
            }
        }
        -not $isExcluded
    } | Sort-Object -Unique | Select-Object -First 30
    Write-Host "Filtered scheduled tasks: $($availableTasks -join ", ")"
} catch {
    Write-Host "[ERROR] Failed to retrieve scheduled tasks. $($_.Exception.Message)" -ForegroundColor Red
    $availableTasks = @()
}

# === GUI Setup ===
$form = New-Object Windows.Forms.Form
$form.Text = "Gaming Mode Configurator"
$form.Size = New-Object Drawing.Size(520, 720) 
$form.StartPosition = "CenterScreen"
$form.Padding = New-Object Windows.Forms.Padding(10)

$saveButtonPanel = New-Object Windows.Forms.Panel
[int]$saveButtonPanelHeight_int = 50
$saveButtonPanel.Height = $saveButtonPanelHeight_int
$saveButtonPanel.Dock = [System.Windows.Forms.DockStyle]::Bottom
$form.Controls.Add($saveButtonPanel)

$mainPanel = New-Object Windows.Forms.Panel
$mainPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
$form.Controls.Add($mainPanel)

$tabControl = New-Object Windows.Forms.TabControl
$tabControl.Dock = [System.Windows.Forms.DockStyle]::Fill
$mainPanel.Controls.Add($tabControl)

function Add-Section($parentControl, $labelText, [System.Collections.IEnumerable]$items, $configKey, [ref]$currentYOffset) {
    [int]$pcClientW_actual = $parentControl.ClientSize.Width
    
    $label = New-Object Windows.Forms.Label
    $label.Text = $labelText
    $label.Location = New-Object Drawing.Point(10, [int]$currentYOffset.Value)
    [int]$calculatedLabelWidth = $pcClientW_actual - 20
    $label.Size = New-Object Drawing.Size($calculatedLabelWidth, 20)
    $label.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
    $parentControl.Controls.Add($label)
    $currentYOffset.Value += 25

    if ($items -and ($items | Measure-Object).Count -gt 0) {
        foreach ($item in $items) {
            if ([string]::IsNullOrWhiteSpace($item)) { continue }
            $cb = New-Object Windows.Forms.CheckBox
            $cb.Text = $item.ToString()
            $cb.Location = New-Object Drawing.Point(15, [int]$currentYOffset.Value)
            [int]$calculatedCbWidth = $pcClientW_actual - 30
            $cb.Size = New-Object Drawing.Size($calculatedCbWidth, 20)
            $cb.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
            $cb.Checked = $config[$configKey] -contains $item
            $cb.Tag = @{ Type = $configKey; Name = $item }
            $parentControl.Controls.Add($cb)
            $currentYOffset.Value += 25
        }
    } else {
        $noItemsLabel = New-Object Windows.Forms.Label
        $noItemsLabel.Text = " (No items found or applicable for auto-scan)"
        $noItemsLabel.Location = New-Object Drawing.Point(15, [int]$currentYOffset.Value)
        [int]$calculatedNoItemsLabelWidth = $pcClientW_actual - 30
        $noItemsLabel.Size = New-Object Drawing.Size($calculatedNoItemsLabelWidth, 20)
        $noItemsLabel.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
        $parentControl.Controls.Add($noItemsLabel)
        $currentYOffset.Value += 25
    }
    $currentYOffset.Value += 10
}

function Add-CustomSection($parentControl, $labelText, $configKey, [ref]$configRef, [ref]$currentYOffset) {
    [int]$pcClientW_actual = $parentControl.ClientSize.Width
    
    $customListLabel = New-Object Windows.Forms.Label
    $customListLabel.Text = $labelText
    $customListLabel.Location = New-Object Drawing.Point(10, [int]$currentYOffset.Value)
    [int]$calculatedCustomListLabelWidth = $pcClientW_actual - 20
    $customListLabel.Size = New-Object Drawing.Size($calculatedCustomListLabelWidth, 20)
    $customListLabel.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
    $parentControl.Controls.Add($customListLabel)
    $currentYOffset.Value += 25

    $txtCustomItem = New-Object Windows.Forms.TextBox
    $txtCustomItem.Location = New-Object Drawing.Point(15, [int]$currentYOffset.Value)
    [int]$calculatedTxtCustomItemWidth = $pcClientW_actual - 130
    $txtCustomItem.Size = New-Object Drawing.Size($calculatedTxtCustomItemWidth, 20)
    $txtCustomItem.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
    $parentControl.Controls.Add($txtCustomItem)

    $btnAddCustom = New-Object Windows.Forms.Button
    $btnAddCustom.Text = "Add"
    [int]$calculatedBtnAddCustomX = $pcClientW_actual - 105
    [int]$calculatedBtnAddCustomY = [int]$currentYOffset.Value - 2
    $btnAddCustom.Location = New-Object Drawing.Point($calculatedBtnAddCustomX, $calculatedBtnAddCustomY)
    $btnAddCustom.Size = New-Object Drawing.Size(75, 25)
    $btnAddCustom.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
    $parentControl.Controls.Add($btnAddCustom)
    $currentYOffset.Value += 30

    $lbCustomItems = New-Object Windows.Forms.ListBox
    $lbCustomItems.Location = New-Object Drawing.Point(15, [int]$currentYOffset.Value)
    [int]$calculatedLbCustomItemsWidth = $pcClientW_actual - 130
    $lbCustomItems.Size = New-Object Drawing.Size($calculatedLbCustomItemsWidth, 100)
    $lbCustomItems.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right -bor [System.Windows.Forms.AnchorStyles]::Bottom
    $lbCustomItems.SelectionMode = [Windows.Forms.SelectionMode]::One
    if ($configRef.Value[$configKey]) {
        $configRef.Value[$configKey] | ForEach-Object { [void]$lbCustomItems.Items.Add($_) }
    }
    $parentControl.Controls.Add($lbCustomItems)
    
    $btnRemoveCustom = New-Object Windows.Forms.Button
    $btnRemoveCustom.Text = "Remove"
    $btnRemoveCustom.Size = New-Object Drawing.Size(75, 25)
    [int]$lbH_actual = $lbCustomItems.Height
    [int]$btnRH_actual = $btnRemoveCustom.Height
    [int]$calculatedBtnRemoveCustomX = $pcClientW_actual - 105
    [int]$calculatedBtnRemoveCustomY = [int]($currentYOffset.Value + ($lbH_actual / 2) - ($btnRH_actual / 2))
    $btnRemoveCustom.Location = New-Object Drawing.Point($calculatedBtnRemoveCustomX, $calculatedBtnRemoveCustomY)
    $btnRemoveCustom.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
    $parentControl.Controls.Add($btnRemoveCustom)

    $btnAddCustom.Add_Click({
        $newItem = $txtCustomItem.Text.Trim()
        if (-not [string]::IsNullOrWhiteSpace($newItem) -and -not $lbCustomItems.Items.Contains($newItem)) {
            [void]$lbCustomItems.Items.Add($newItem)
            $configRef.Value[$configKey] = ($lbCustomItems.Items | ForEach-Object { $_ })
            $txtCustomItem.Clear()
            Write-Host "Added to custom $configKey list: $newItem"
        }
    })

    $btnRemoveCustom.Add_Click({
        $selectedItem = $lbCustomItems.SelectedItem
        if ($selectedItem) {
            $lbCustomItems.Items.Remove($selectedItem)
            $configRef.Value[$configKey] = ($lbCustomItems.Items | ForEach-Object { $_ })
            Write-Host "Removed from custom $configKey list: $selectedItem"
        }
    })
    [int]$lbHFinal_actual = $lbCustomItems.Height
    $currentYOffset.Value += $lbHFinal_actual + 10
}

$tabPageServices = New-Object Windows.Forms.TabPage; $tabPageServices.Text = "Services"; $tabPageServices.AutoScroll = $true; $tabPageServices.Padding = New-Object Windows.Forms.Padding(5)
$yOffsetServices = 10
Add-Section $tabPageServices "Auto-Detected Services (Check to Stop):" $availableServices "Services" ([ref]$yOffsetServices)
Add-CustomSection $tabPageServices "Custom Services to Always Stop:" "CustomServices" ([ref]$config) ([ref]$yOffsetServices)
$tabControl.Controls.Add($tabPageServices)

$tabPageProcesses = New-Object Windows.Forms.TabPage; $tabPageProcesses.Text = "Processes"; $tabPageProcesses.AutoScroll = $true; $tabPageProcesses.Padding = New-Object Windows.Forms.Padding(5)
$yOffsetProcesses = 10
Add-Section $tabPageProcesses "Auto-Detected Processes (Check to Kill):" $availableProcesses "Processes" ([ref]$yOffsetProcesses)
Add-CustomSection $tabPageProcesses "Custom Processes to Always Kill:" "CustomProcesses" ([ref]$config) ([ref]$yOffsetProcesses)
$tabControl.Controls.Add($tabPageProcesses)

$tabPageTasks = New-Object Windows.Forms.TabPage; $tabPageTasks.Text = "Scheduled Tasks"; $tabPageTasks.AutoScroll = $true; $tabPageTasks.Padding = New-Object Windows.Forms.Padding(5)
$yOffsetTasks = 10
Add-Section $tabPageTasks "Auto-Detected Tasks (Check to Stop/Disable):" $availableTasks "Tasks" ([ref]$yOffsetTasks)
Add-CustomSection $tabPageTasks "Custom Scheduled Tasks to Always Stop/Disable:" "CustomTasks" ([ref]$config) ([ref]$yOffsetTasks)
$tabControl.Controls.Add($tabPageTasks)

$btnSave = New-Object Windows.Forms.Button
$btnSave.Text = "Save and Apply"
$btnSave.Size = New-Object Drawing.Size(150, 30)
[int]$sbpClientW_actual = $saveButtonPanel.ClientSize.Width
[int]$sbpClientH_actual = $saveButtonPanel.ClientSize.Height
[int]$btnSaveW_actual = $btnSave.Width
[int]$btnSaveH_actual = $btnSave.Height
[int]$btnSaveX_calculated = ($sbpClientW_actual - $btnSaveW_actual) / 2
[int]$btnSaveY_calculated = ($sbpClientH_actual - $btnSaveH_actual) / 2
$btnSave.Location = New-Object Drawing.Point($btnSaveX_calculated, $btnSaveY_calculated)
$btnSave.Anchor = [System.Windows.Forms.AnchorStyles]::None
$saveButtonPanel.Controls.Add($btnSave)

$btnSave.Add_Click({
    $newConfig = @{ Services=@(); Processes=@(); Tasks=@(); CustomServices=@(); CustomProcesses=@(); CustomTasks=@() }
    
    foreach ($tabPage in $tabControl.TabPages) {
        foreach ($ctrl in $tabPage.Controls) {
            if ($ctrl -is [Windows.Forms.CheckBox] -and $ctrl.Checked) {
                if ($ctrl.Tag -and $ctrl.Tag.Type -and $ctrl.Tag.Name) {
                    $type = $ctrl.Tag.Type 
                    $name = $ctrl.Tag.Name
                    Write-Host "Selected from auto-scan: [$type] $name"
                    $newConfig[$type] += $name
                }
            }
        }
    }

    $newConfig.CustomServices = $config.CustomServices | Get-Unique
    $newConfig.CustomProcesses = $config.CustomProcesses | Get-Unique
    $newConfig.CustomTasks = $config.CustomTasks | Get-Unique
    
    Save-Config $newConfig

    $servicesToActOn = ($newConfig.Services + $newConfig.CustomServices) | Get-Unique
    $processesToActOn = ($newConfig.Processes + $newConfig.CustomProcesses) | Get-Unique
    $tasksToActOn = ($newConfig.Tasks + $newConfig.CustomTasks) | Get-Unique

    foreach ($svc in $servicesToActOn) {
        Write-Host "Stopping service: $svc"
        try {
            $s = Get-Service -Name $svc -ErrorAction Stop
            if ($s.Status -eq "Running") { Stop-Service -Name $svc -Force }
        } catch { Write-Host "[ERROR] Cannot stop service $svc ($($_.Exception.Message))" -ForegroundColor Red }
    }
    foreach ($proc in $processesToActOn) {
        Write-Host "Killing process: $proc"
        try { Stop-Process -Name $proc -Force -ErrorAction Stop } 
        catch { Write-Host "[ERROR] Cannot kill process $proc ($($_.Exception.Message))" -ForegroundColor Red }
    }
    foreach ($task in $tasksToActOn) {
        Write-Host "Disabling task: $task"
        try {
            Disable-ScheduledTask -TaskName $task -ErrorAction SilentlyContinue
            Stop-ScheduledTask -TaskName $task -ErrorAction SilentlyContinue
        } catch { Write-Host "[ERROR] Cannot disable/stop task $task ($($_.Exception.Message))" -ForegroundColor Red }
    }

    [Windows.Forms.MessageBox]::Show("Gaming Mode settings applied! Check console for details.", "Done", [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Information)
    $form.Close()
})

# === Show Form ===
[void]$form.ShowDialog()