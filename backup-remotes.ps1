function Get-ChildItemLimitedDepth {
    param (
        [Alias("PSPath")]
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [String]$Path,

        [Parameter(Position = 1)]
        [Int32]$Depth = 0
    )

    if (Test-Path $Path) {
        Get-ChildItem -Path $Path -Force -ErrorAction SilentlyContinue | ForEach-Object {
            $_
            if ($Depth -gt 0 -and $_.PSIsContainer) {
                Get-ChildItemLimitedDepth -Path $_.FullName -Depth ($Depth - 1)
            }
        }
    }
}

$homePath = [Environment]::GetFolderPath('UserProfile')
$sourcePath = Join-Path -Path $homePath -ChildPath 'Documents'

Get-ChildItemLimitedDepth -Path $sourcePath -Depth 3 | Where-Object { $_.Name -eq '.git' -and $_.PSIsContainer } | ForEach-Object {
    Set-Location -Path $_.Parent.FullName
    $parentDir = $_.Parent.FullName
    $remotes = git remote -v
    $remotes.Split("`n") | Where-Object { $_ -match '(origin).*(fetch)' } | ForEach-Object {
        $remoteUrl = ($_ -split '\s+')[1]
        Write-Output "`n# Create directory and navigate to it"
        Write-Output "mkdir `"$parentDir`" -Force"
        Write-Output "cd `"$parentDir`""
        Write-Output "# Initialize git and add remote"
        Write-Output "git init"
        # Write-Output "git remote remove origin"
        Write-Output "git remote add origin $remoteUrl"
    }
}
