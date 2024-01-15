# Create a COM object to interact with the Windows Update API
$UpdateSession = New-Object -ComObject Microsoft.Update.Session
$UpdateSearcher = $UpdateSession.CreateUpdateSearcher()

Write-Output "Searching for available updates..."

# Search for all available updates
try {
    $SearchResult = $UpdateSearcher.Search("IsInstalled=0")
} catch {
    Write-Error "Error during update search: $_"
    exit
}

$UpdatesToDownload = New-Object -ComObject Microsoft.Update.UpdateColl
$foundUpdates = $false

foreach ($Update in $SearchResult.Updates) {
    if ($Update.Driver) {
        $UpdatesToDownload.Add($Update) | Out-Null
        Write-Output "Driver Update Found: $($Update.Title)"
        $foundUpdates = $true
    }
}

if (-not $foundUpdates) {
    Write-Output "No driver updates found."
    exit
}

# Ask the user if they want to download the updates
$DownloadUpdates = Read-Host "Do you want to download these updates? (Y/N)"
if ($DownloadUpdates -eq 'Y') {
    $Downloader = $UpdateSession.CreateUpdateDownloader()
    $Downloader.Updates = $UpdatesToDownload

    try {
        $DownloadResult = $Downloader.Download()
        Write-Output "Download Result: $($DownloadResult.ResultCode)"
    } catch {
        Write-Error "Error during update download: $_"
    }
} else {
    Write-Output "Update download skipped by user."
}
