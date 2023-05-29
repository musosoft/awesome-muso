$homePath = [Environment]::GetFolderPath('UserProfile')
$sourcePath = Join-Path -Path $homePath -ChildPath 'Documents'
$destinationPath = Join-Path -Path (Get-Location) -ChildPath 'private\sftp'

Get-ChildItem -Path $sourcePath -Filter sftp.json -Recurse -File | ForEach-Object {
    $dest = $_.FullName.Replace($sourcePath, $destinationPath)
    $destDir = Split-Path -Path $dest -Parent
    if (!(Test-Path -Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force
    }
    if ($_.FullName -ne $dest) {
        Copy-Item -Path $_.FullName -Destination $dest
    }
}
