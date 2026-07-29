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

function Test-ElevationCancelledError {
    param($ErrorRecord)

    return (
        $ErrorRecord.Exception.HResult -eq -2147023673 -or
        $ErrorRecord.Exception.Message -match 'cancelled by the user'
    )
}

$statusPath = [System.IO.Path]::Combine($env:TEMP, 'warden-doh-template-' + [guid]::NewGuid().ToString() + '.txt')
$childPath = [System.IO.Path]::Combine($env:TEMP, 'warden-doh-template-child-' + [guid]::NewGuid().ToString() + '.ps1')
$allowFallbackToUdpLiteral = if ([bool]$AllowFallbackToUdp) { '$true' } else { '$false' }
$autoUpgradeLiteral = if ([bool]$AutoUpgrade) { '$true' } else { '$false' }

@"
`$ErrorActionPreference = 'Stop'
try {
    `$existing = Get-DnsClientDohServerAddress -ServerAddress '$ServerAddress' -ErrorAction SilentlyContinue | Select-Object -First 1
    `$status = if (`$existing) { 'updated' } else { 'installed' }

    if (`$existing) {
        Remove-DnsClientDohServerAddress -ServerAddress '$ServerAddress' -ErrorAction SilentlyContinue
    }

    Add-DnsClientDohServerAddress -ServerAddress '$ServerAddress' -DohTemplate '$DohTemplate' -AllowFallbackToUdp $allowFallbackToUdpLiteral -AutoUpgrade $autoUpgradeLiteral
    Set-Content -Path '$statusPath' -Value `$status -NoNewline
    exit 0
} catch {
    Set-Content -Path '$statusPath' -Value ('error:' + `$_.Exception.Message) -NoNewline
    exit 1
}
"@ | Set-Content -Path $childPath -NoNewline

try {
    try {
        $process = Start-Process powershell.exe -Verb RunAs -Wait -PassThru -ArgumentList @(
            '-NoProfile',
            '-ExecutionPolicy',
            'Bypass',
            '-File',
            $childPath
        )
    } catch {
        if (Test-ElevationCancelledError $_) {
            Write-Output 'elevation_cancelled'
            return
        }

        Write-Output 'elevation_failed'
        return
    }

    if (-not (Test-Path $statusPath)) {
        Write-Output 'elevation_failed'
        return
    }

    $status = Get-Content -Path $statusPath -Raw
    if ($status -eq 'installed' -or $status -eq 'updated') {
        Write-Output $status
        return
    }

    if ($process.ExitCode -ne 0) {
        Write-Output 'elevation_failed'
        return
    }

    Write-Output 'elevation_failed'
} finally {
    Remove-Item -Path $childPath -ErrorAction SilentlyContinue
    Remove-Item -Path $statusPath -ErrorAction SilentlyContinue
}
