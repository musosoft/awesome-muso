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
        Write-Error "Restoring gaming mode requires administrator privileges: $($_.Exception.Message)"
    }
    return
}

$dataDirectory = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'GamingMode'
$statePath = Join-Path $dataDirectory 'state.json'

function Write-JsonAtomic($Value, [string]$Path) {
    $temporaryPath = "$Path.$PID.tmp"
    $Value | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $temporaryPath -Encoding UTF8
    Move-Item -LiteralPath $temporaryPath -Destination $Path -Force
}

function Resolve-TaskName([string]$Identity) {
    $identity = $Identity.Trim().Replace('/', '\')
    if (-not $identity.StartsWith('\')) { $identity = '\' + $identity }
    $separator = $identity.LastIndexOf('\')
    [pscustomobject]@{
        TaskPath = $identity.Substring(0, $separator + 1)
        TaskName = $identity.Substring($separator + 1)
    }
}

if (-not (Test-Path -LiteralPath $statePath)) {
    Write-Host 'Gaming mode is not active; nothing needs to be restored.' -ForegroundColor Yellow
    return
}

try {
    $loaded = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
    $state = [ordered]@{
        Version = 1
        Active = $true
        EnteredAt = [string]$loaded.EnteredAt
        Services = @($loaded.Services)
        Processes = @($loaded.Processes)
        Tasks = @($loaded.Tasks)
    }
} catch {
    Write-Error "Cannot read '$statePath': $($_.Exception.Message)"
    return
}

Write-Host 'Restoring the items changed by Gaming Mode...' -ForegroundColor Cyan

$remainingServices = @()
foreach ($record in @($state.Services)) {
    try {
        $service = Get-Service -Name ([string]$record.Name) -ErrorAction Stop
        if ($service.Status -ne [System.ServiceProcess.ServiceControllerStatus]::Running) {
            Start-Service -Name $service.Name -ErrorAction Stop
            $service.WaitForStatus([System.ServiceProcess.ServiceControllerStatus]::Running, [TimeSpan]::FromSeconds(20))
        }
        Write-Host "Restored service: $($service.Name)"
    } catch {
        $remainingServices += $record
        Write-Warning "Service '$($record.Name)' could not be restored: $($_.Exception.Message)"
    }
}
$state.Services = $remainingServices
Write-JsonAtomic $state $statePath

$remainingProcesses = @()
$matchedProcessIds = New-Object 'System.Collections.Generic.HashSet[uint32]'
foreach ($record in @($state.Processes)) {
    try {
        $alreadyRunning = $false
        $running = @(Get-CimInstance -ClassName Win32_Process -Filter ("Name='{0}'" -f ([string]$record.Name).Replace("'", "''")) -ErrorAction Stop)
        foreach ($candidate in $running) {
            if ($matchedProcessIds.Contains([uint32]$candidate.ProcessId)) { continue }
            if (-not [string]::IsNullOrWhiteSpace([string]$record.CommandLine) -and
                [string]$candidate.CommandLine -eq [string]$record.CommandLine) {
                $alreadyRunning = $true
                [void]$matchedProcessIds.Add([uint32]$candidate.ProcessId)
                break
            }
            if ([string]::IsNullOrWhiteSpace([string]$record.CommandLine) -and
                -not [string]::IsNullOrWhiteSpace([string]$record.Path) -and
                [string]$candidate.ExecutablePath -eq [string]$record.Path) {
                $alreadyRunning = $true
                [void]$matchedProcessIds.Add([uint32]$candidate.ProcessId)
                break
            }
        }

        if (-not $alreadyRunning) {
            if (-not [string]::IsNullOrWhiteSpace([string]$record.CommandLine)) {
                $result = Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{
                    CommandLine = [string]$record.CommandLine
                } -ErrorAction Stop
                if ($result.ReturnValue -ne 0) { throw "Win32_Process.Create returned $($result.ReturnValue)." }
                [void]$matchedProcessIds.Add([uint32]$result.ProcessId)
            } elseif (-not [string]::IsNullOrWhiteSpace([string]$record.Path)) {
                $started = Start-Process -FilePath ([string]$record.Path) -PassThru -ErrorAction Stop
                [void]$matchedProcessIds.Add([uint32]$started.Id)
            } else {
                throw 'No executable path or command line was recorded.'
            }
        }
        Write-Host "Restored process: $($record.Name)"
    } catch {
        $remainingProcesses += $record
        Write-Warning "Process '$($record.Name)' could not be restored: $($_.Exception.Message)"
    }
}
$state.Processes = $remainingProcesses
Write-JsonAtomic $state $statePath

$remainingTasks = @()
foreach ($record in @($state.Tasks)) {
    try {
        $resolved = Resolve-TaskName ([string]$record.Identity)
        if ($record.WasEnabled) {
            Enable-ScheduledTask -TaskName $resolved.TaskName -TaskPath $resolved.TaskPath -ErrorAction Stop | Out-Null
        }
        if ($record.WasRunning) {
            $task = Get-ScheduledTask -TaskName $resolved.TaskName -TaskPath $resolved.TaskPath -ErrorAction Stop
            if ($task.State -ne 'Running') {
                Start-ScheduledTask -TaskName $resolved.TaskName -TaskPath $resolved.TaskPath -ErrorAction Stop
            }
        }
        Write-Host "Restored scheduled task: $($record.Identity)"
    } catch {
        $remainingTasks += $record
        Write-Warning "Scheduled task '$($record.Identity)' could not be restored: $($_.Exception.Message)"
    }
}
$state.Tasks = $remainingTasks

if ($state.Services.Count -eq 0 -and $state.Processes.Count -eq 0 -and $state.Tasks.Count -eq 0) {
    Remove-Item -LiteralPath $statePath -Force
    Write-Host 'Gaming Mode changes were restored.' -ForegroundColor Green
} else {
    Write-JsonAtomic $state $statePath
    Write-Warning 'Some items could not be restored. Run this script again after resolving the warnings.'
}
