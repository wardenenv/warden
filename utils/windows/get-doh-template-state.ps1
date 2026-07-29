param(
    [Parameter(Mandatory = $true)]
    [string]$ServerAddress,

    [Parameter(Mandatory = $true)]
    [string]$DohTemplate,

    [Parameter(Mandatory = $true)]
    [int]$AllowFallbackToUdp,

    [Parameter(Mandatory = $true)]
    [int]$AutoUpgrade
)

$ErrorActionPreference = 'Stop'
$allowFallbackToUdpExpected = [bool]$AllowFallbackToUdp
$autoUpgradeExpected = [bool]$AutoUpgrade

$entry = Get-DnsClientDohServerAddress -ServerAddress $ServerAddress -ErrorAction SilentlyContinue | Select-Object -First 1

if (-not $entry) {
    Write-Output 'State=missing'
    exit 0
}

$state = if (
    $entry.DohTemplate -eq $DohTemplate -and
    $entry.AllowFallbackToUdp -eq $allowFallbackToUdpExpected -and
    $entry.AutoUpgrade -eq $autoUpgradeExpected
) {
    'present'
} else {
    'different'
}

Write-Output "State=$state"
Write-Output "Template=$($entry.DohTemplate)"
Write-Output "AllowFallbackToUdp=$($entry.AllowFallbackToUdp)"
Write-Output "AutoUpgrade=$($entry.AutoUpgrade)"
