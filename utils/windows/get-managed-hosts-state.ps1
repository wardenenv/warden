param(
    [Parameter(Mandatory = $true)]
    [string]$BlockStart,

    [Parameter(Mandatory = $true)]
    [string]$BlockEnd,

    [Parameter(Mandatory = $true)]
    [string]$EntriesText
)

$ErrorActionPreference = 'Stop'

$expectedEntries = if ([string]::IsNullOrEmpty($EntriesText)) {
    @()
} else {
    $EntriesText.Split('|') | Where-Object { $_ -ne '' }
}

$hostsPath = Join-Path $env:SystemRoot 'System32\drivers\etc\hosts'
$lines = if (Test-Path $hostsPath) {
    [System.IO.File]::ReadAllLines($hostsPath)
} else {
    @()
}

$startIndex = -1
$endIndex = -1
for ($i = 0; $i -lt $lines.Length; $i++) {
    if ($lines[$i] -eq $BlockStart) {
        $startIndex = $i
        continue
    }

    if ($startIndex -ge 0 -and $lines[$i] -eq $BlockEnd) {
        $endIndex = $i
        break
    }
}

if ($startIndex -lt 0 -or $endIndex -lt 0 -or $endIndex -le $startIndex) {
    Write-Output 'State=missing'
    exit 0
}

$currentEntries = @()
if ($endIndex -gt ($startIndex + 1)) {
    $currentEntries = $lines[($startIndex + 1)..($endIndex - 1)] | Where-Object { $_ -ne '' }
}

$state = if (
    $currentEntries.Count -eq $expectedEntries.Count -and
    (@(Compare-Object -ReferenceObject $expectedEntries -DifferenceObject $currentEntries -SyncWindow 0).Count -eq 0)
) {
    'present'
} else {
    'different'
}

Write-Output "State=$state"
Write-Output "Entries=$([string]::Join('|', $currentEntries))"
