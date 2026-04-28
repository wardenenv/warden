param(
    [Parameter(Mandatory = $true)]
    [string]$BlockStart,

    [Parameter(Mandatory = $true)]
    [string]$BlockEnd,

    [Parameter(Mandatory = $true)]
    [string]$EntriesText
)

$ErrorActionPreference = 'Stop'

function Test-ElevationCancelledError {
    param($ErrorRecord)

    return (
        $ErrorRecord.Exception.HResult -eq -2147023673 -or
        $ErrorRecord.Exception.Message -match 'cancelled by the user'
    )
}

$statusPath = [System.IO.Path]::Combine($env:TEMP, 'warden-hosts-status-' + [guid]::NewGuid().ToString() + '.txt')
$childPath = [System.IO.Path]::Combine($env:TEMP, 'warden-hosts-child-' + [guid]::NewGuid().ToString() + '.ps1')

@"
`$ErrorActionPreference = 'Stop'
try {
    `$hostsPath = Join-Path `$env:SystemRoot 'System32\drivers\etc\hosts'
    `$lines = if (Test-Path `$hostsPath) { [System.IO.File]::ReadAllLines(`$hostsPath) } else { @() }
    `$entries = '$EntriesText'.Split('|') | Where-Object { `$_ -ne '' }

    `$startIndex = -1
    `$endIndex = -1
    for (`$i = 0; `$i -lt `$lines.Length; `$i++) {
        if (`$lines[`$i] -eq '$BlockStart') {
            `$startIndex = `$i
            continue
        }

        if (`$startIndex -ge 0 -and `$lines[`$i] -eq '$BlockEnd') {
            `$endIndex = `$i
            break
        }
    }

    `$status = 'installed'
    `$currentEntries = @()
    `$baseLines = @()

    if (`$startIndex -ge 0 -and `$endIndex -gt `$startIndex) {
        if (`$endIndex -gt (`$startIndex + 1)) {
            `$currentEntries = `$lines[(`$startIndex + 1)..(`$endIndex - 1)] | Where-Object { `$_ -ne '' }
        }
        `$status = 'updated'
        if (
            `$currentEntries.Count -eq `$entries.Count -and
            (@(Compare-Object -ReferenceObject `$entries -DifferenceObject `$currentEntries -SyncWindow 0).Count -eq 0)
        ) {
            `$status = 'present'
        }

        if (`$startIndex -gt 0) {
            `$baseLines += `$lines[0..(`$startIndex - 1)]
        }
        if (`$endIndex -lt (`$lines.Length - 1)) {
            `$baseLines += `$lines[(`$endIndex + 1)..(`$lines.Length - 1)]
        }
    } else {
        `$baseLines = @(`$lines)
    }

    if (`$status -eq 'present') {
        Set-Content -Path '$statusPath' -Value `$status -NoNewline
        exit 0
    }

    while (`$baseLines.Count -gt 0 -and [string]::IsNullOrWhiteSpace(`$baseLines[-1])) {
        `$baseLines = if (`$baseLines.Count -gt 1) { `$baseLines[0..(`$baseLines.Count - 2)] } else { @() }
    }

    `$newLines = New-Object System.Collections.Generic.List[string]
    foreach (`$line in `$baseLines) {
        [void]`$newLines.Add(`$line)
    }
    if (`$newLines.Count -gt 0) {
        [void]`$newLines.Add('')
    }
    [void]`$newLines.Add('$BlockStart')
    foreach (`$entry in `$entries) {
        [void]`$newLines.Add(`$entry)
    }
    [void]`$newLines.Add('$BlockEnd')

    [System.IO.File]::WriteAllLines(`$hostsPath, `$newLines)
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
    if ($status -eq 'installed' -or $status -eq 'updated' -or $status -eq 'present') {
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
