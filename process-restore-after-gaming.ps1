# ========================
# PowerShell Work Mode Restore
# ========================

Write-Host "♻️ Restoring necessary services and applications for Work Mode..." -ForegroundColor Cyan

# --- Services to Start ---
$servicesToStart = @(
    "RustDesk",
    "TeamViewer",
    "Spooler",
    "WSearch",
    "SysMain",
    "StiSvc",
    "WpnUserService_6a95b",
    "OneSyncSvc_6a95b",
    "wuauserv"
)

foreach ($svc in $servicesToStart) {
    $service = Get-Service -Name $svc -ErrorAction SilentlyContinue
    if ($service -and $service.Status -ne "Running") {
        Write-Host "Starting service: $svc"
        Start-Service -Name $svc
    }
}

# --- Startup Applications ---
$startupApps = @(
    "C:\Program Files\RustDesk\RustDesk.exe",
    "C:\Program Files\TeamViewer\TeamViewer.exe",
    "C:\Program Files\Google\Drive File Stream\105.0.1.0\GoogleDriveFS.exe",
    "C:\Program Files\CopyQ\copyq.exe",
    "C:\Users\muso\AppData\Local\Programs\UniGetUI\UniGetUI.exe",
    "C:\WINDOWS\system32\OneDriveSetup.exe",
    "C:\Users\muso\AppData\Local\PowerToys\PowerToys.exe"
)

foreach ($app in $startupApps) {
    if (Test-Path $app) {
        Write-Host "Starting application: $app"
        Start-Process $app
    }
}

Write-Host "✅ Work mode restored." -ForegroundColor Green
