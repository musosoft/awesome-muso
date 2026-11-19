#Requires -Version 5.1

$ErrorActionPreference = 'Stop'

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
        Write-Error "Gaming mode requires administrator privileges: $($_.Exception.Message)"
    }
    return
}

$dataDirectory = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'GamingMode'
$configPath = Join-Path $dataDirectory 'config.json'
$statePath = Join-Path $dataDirectory 'state.json'

function Write-JsonAtomic($Value, [string]$Path) {
    $temporaryPath = "$Path.$PID.tmp"
    $Value | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $temporaryPath -Encoding UTF8
    Move-Item -LiteralPath $temporaryPath -Destination $Path -Force
}

function Get-StringArray($Object, [string]$Property) {
    if ($null -eq $Object -or $null -eq $Object.PSObject.Properties[$Property]) { return @() }
    @($Object.$Property | ForEach-Object { if ($null -ne $_) { ([string]$_).Trim() } } |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Sort-Object -Unique)
}

function Resolve-TaskName([string]$Identity) {
    $identity = $Identity.Trim().Replace('/', '\')
    if (-not $identity.StartsWith('\')) { $identity = '\' + $identity }
    $separator = $identity.LastIndexOf('\')
    [pscustomobject]@{
        TaskPath = $identity.Substring(0, $separator + 1)
        TaskName = $identity.Substring($separator + 1)
        Identity = $identity
    }
}

if (-not (Test-Path -LiteralPath $dataDirectory)) {
    New-Item -ItemType Directory -Path $dataDirectory -Force | Out-Null
}

if (-not (Test-Path -LiteralPath $configPath)) {
    Write-Warning "No gaming mode configuration exists. Run gaming-mode.ps1 first. No changes were made."
    return
}

try {
    $config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
} catch {
    Write-Error "Cannot read '$configPath': $($_.Exception.Message)"
    return
}

if (Test-Path -LiteralPath $statePath) {
    try {
        $existingState = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
        if ($existingState.Active) {
            Write-Host 'Gaming mode is already active; no additional items were changed.' -ForegroundColor Yellow
            return
        }
    } catch {
        Write-Error "The existing state file is invalid. Restore or remove '$statePath' before entering gaming mode."
        return
    }
}

$state = [ordered]@{
    Version = 1
    Active = $true
    EnteredAt = (Get-Date).ToString('o')
    Services = @()
    Processes = @()
    Tasks = @()
}
Write-JsonAtomic $state $statePath

Write-Host 'Entering Gaming Mode...' -ForegroundColor Yellow

foreach ($serviceName in (Get-StringArray $config 'Services')) {
    try {
        $service = Get-Service -Name $serviceName -ErrorAction Stop
        if ($service.Status -ne [System.ServiceProcess.ServiceControllerStatus]::Running) { continue }
        Stop-Service -Name $serviceName -Force -ErrorAction Stop
        $service.WaitForStatus([System.ServiceProcess.ServiceControllerStatus]::Stopped, [TimeSpan]::FromSeconds(20))
        $state.Services += [ordered]@{ Name = $service.Name }
        Write-JsonAtomic $state $statePath
        Write-Host "Stopped service: $($service.Name)"
    } catch {
        Write-Warning "Service '$serviceName' was not changed: $($_.Exception.Message)"
    }
}

$processTargets = Get-StringArray $config 'Processes'
if ($processTargets.Count -gt 0) {
    try {
        $allProcesses = @(Get-CimInstance -ClassName Win32_Process -ErrorAction Stop)
    } catch {
        Write-Warning "Processes could not be enumerated: $($_.Exception.Message)"
        $allProcesses = @()
    }

    foreach ($target in $processTargets) {
        $normalizedTarget = $target -replace '(?i)\.exe$', ''
        $matches = @($allProcesses | Where-Object {
            ([string]$_.Name -replace '(?i)\.exe$', '') -ieq $normalizedTarget
        })
        foreach ($process in $matches) {
            if ($process.ProcessId -eq $PID) { continue }
            try {
                $record = [ordered]@{
                    Name = [string]$process.Name
                    Path = [string]$process.ExecutablePath
                    CommandLine = [string]$process.CommandLine
                }
                Stop-Process -Id $process.ProcessId -Force -ErrorAction Stop
                try { Wait-Process -Id $process.ProcessId -Timeout 10 -ErrorAction SilentlyContinue } catch {}
                if (Get-Process -Id $process.ProcessId -ErrorAction SilentlyContinue) {
                    throw 'The process is still running.'
                }
                $state.Processes += $record
                Write-JsonAtomic $state $statePath
                Write-Host "Stopped process: $($process.Name) (PID $($process.ProcessId))"
            } catch {
                Write-Warning "Process '$($process.Name)' (PID $($process.ProcessId)) was not changed: $($_.Exception.Message)"
            }
        }
    }
}

foreach ($taskIdentity in (Get-StringArray $config 'Tasks')) {
    try {
        $resolved = Resolve-TaskName $taskIdentity
        if ([string]::IsNullOrWhiteSpace($resolved.TaskName)) { throw 'A task name is required.' }
        $task = Get-ScheduledTask -TaskName $resolved.TaskName -TaskPath $resolved.TaskPath -ErrorAction Stop
        if ($task.State -ne 'Running') { continue }

        $wasEnabled = $task.Settings.Enabled
        Stop-ScheduledTask -TaskName $resolved.TaskName -TaskPath $resolved.TaskPath -ErrorAction Stop
        $taskRecord = [ordered]@{
            Identity = $resolved.Identity
            WasEnabled = [bool]$wasEnabled
            WasRunning = $true
        }
        $state.Tasks += $taskRecord
        Write-JsonAtomic $state $statePath

        if ($wasEnabled) {
            try {
                Disable-ScheduledTask -TaskName $resolved.TaskName -TaskPath $resolved.TaskPath -ErrorAction Stop | Out-Null
            } catch {
                # The stopped task is already recorded and will still be restarted on restore.
                Write-Warning "Scheduled task '$taskIdentity' was stopped but could not be disabled: $($_.Exception.Message)"
            }
        }
        Write-Host "Stopped scheduled task: $($resolved.Identity)"
    } catch {
        Write-Warning "Scheduled task '$taskIdentity' was not changed: $($_.Exception.Message)"
    }
}

Write-Host 'Gaming Mode is active.' -ForegroundColor Green
