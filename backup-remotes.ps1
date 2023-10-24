# Define the output file path
$currentDir = Get-Location
$outputDir = Join-Path -Path $currentDir -ChildPath "private"
$outputFilePath = Join-Path -Path $outputDir -ChildPath "remotes.ps1"

# Create the directory if it doesn't exist
if (-Not (Test-Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory
}

# Clear the output file if it exists
if (Test-Path $outputFilePath) {
    Clear-Content $outputFilePath
}

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

    if (![string]::IsNullOrEmpty($remotes)) {
        $remotes.Split("`n") | Where-Object { $_ -match '(origin).*(fetch)' } | ForEach-Object {
            $remoteUrl = ($_ -split '\s+')[1]
            $output = @"
`n# Create directory and navigate to it
mkdir `"$parentDir`" -Force
takeown /F `"$parentDir`" /R
cd `"$parentDir`"
# Initialize git and add remote
git init
git remote add origin $remoteUrl
cd `"$currentDir`"
"@
            # Write to the output file
            $output | Out-File -FilePath $outputFilePath -Append
        }
    }
    else {
        "No remotes found for $parentDir" | Out-File -FilePath $outputFilePath -Append
    }
}
