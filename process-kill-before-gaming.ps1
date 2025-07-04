Write-Host "🔻 Entering Gaming Mode... Cleaning up system." -ForegroundColor Yellow

# === Stop Non-Essential Services ===
$servicesToStop = @(
    "AGMService", "CamoService", "RustDesk", "TeamViewer",
    "Spooler", "SysMain", "WSearch", "StiSvc",
    "StateRepository", "WpnUserService_6a294", "CDPUserSvc_6a294", "OneSyncSvc_6a294", "NordUpdateService", "nordvpn-service"
)

foreach ($svc in $servicesToStop) {
    $s = Get-Service -Name $svc -ErrorAction SilentlyContinue
    if ($s -and $s.Status -eq "Running") {
        Write-Host "Stopping service: $svc"
        Stop-Service -Name $svc -Force
    }
}

# === Kill Non-Essential Processes ===
$processesToKill = @(
    "Vesktop", "Beeper", "PowerToys", "PowerToys.PowerLauncher",
    "PowerToys.ColorPickerUI", "PowerToys.AdvancedPaste", "PowerToys.Peek.UI", 
    "PowerToys.Awake", "PowerToys.FancyZones", "PowerToys.CropAndLock", "PowerToys.AlwaysOnTop", "Microsoft.CmdPal.UI", "AMDInstallManager",
    "RustDesk", "TeamViewer", "GoogleDriveFS", "CopyQ", "Code", "thorium", "git",
    "TextInputHost", "SearchHost", "SearchIndexer", "SearchProtocolHost",
    "explorer", "SystemSettings", "StartMenuExperienceHost", "ShellExperienceHost",
    "ApplicationFrameHost", "ShellHost", "taskhostw", "RuntimeBroker",
    "Adobe Crash Processor", "crashpad_handler", "SecurityHealthSystray", "WingetUI", "AdobeNotificationClient", "msedgewebview2", "msedgewebview2", "msedgewebview2", "msedgewebview2", "msedgewebview2", "msedgewebview2", "msedgewebview2", "SearchIndexer", "MicrosoftEdgeUpdate", "NordUpdateService", "nordvpn-service", "wslrelay", "wslservice", "vmcompute", "SearchIndexer", "mobsync", "ollama app", "ollama"
)

foreach ($p in $processesToKill) {
    $proc = Get-Process -Name $p -ErrorAction SilentlyContinue
    if ($proc) {
        Write-Host "Killing process: $p"
        Stop-Process -Name $p -Force
    }
}

# === Stop Scheduled Tasks ===
$scheduledTasksToStop = @(
    "SystemSoundsService", "CacheTask"
)

foreach ($task in $scheduledTasksToStop) {
    try {
        Write-Host "Disabling scheduled task: $task"
        Disable-ScheduledTask -TaskName $task -ErrorAction SilentlyContinue
        Stop-ScheduledTask -TaskName $task -ErrorAction SilentlyContinue
    } catch {}
}

Write-Host "✅ Gaming Mode Activated. System is now optimized for Counter-Strike: Source." -ForegroundColor Green
