#
# Handles UAC elevation for LocalMachine\Root import, passes work to the
# elevated import script, and translates the result back to WSL.
#
param(
    [Parameter(Mandatory = $true)]
    [string]$CertificatePath,

    [Parameter(Mandatory = $true)]
    [string]$Thumbprint,

    [Parameter(Mandatory = $true)]
    [string]$ImportScriptPath
)

$ErrorActionPreference = 'Stop'

function Test-ElevationCancelledError {
    param($ErrorRecord)

    return (
        $ErrorRecord.Exception.HResult -eq -2147023673 -or
        $ErrorRecord.Exception.Message -match 'cancelled by the user'
    )
}

$scriptPath = [System.IO.Path]::Combine($env:TEMP, 'Warden-Import-Root-Certificate-' + [guid]::NewGuid().ToString() + '.ps1')
$statusPath = [System.IO.Path]::Combine($env:TEMP, 'warden-rootca-import-' + [guid]::NewGuid().ToString() + '.txt')
$tempCertPath = [System.IO.Path]::Combine($env:TEMP, 'warden-rootca-' + [guid]::NewGuid().ToString() + '.pem')

Copy-Item $CertificatePath $tempCertPath -Force
Copy-Item $ImportScriptPath $scriptPath -Force

try {
    try {
        $process = Start-Process powershell.exe -Verb RunAs -Wait -PassThru -ArgumentList @(
            '-NoProfile',
            '-ExecutionPolicy',
            'Bypass',
            '-File',
            $scriptPath,
            '-CertificatePath',
            $tempCertPath,
            '-Thumbprint',
            $Thumbprint,
            '-StatusPath',
            $statusPath
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
    if ($status -eq 'policy_blocked') {
        Write-Output 'policy_blocked'
        return
    }

    if ($process.ExitCode -ne 0) {
        Write-Output 'elevation_failed'
        return
    }

    if ($status -ne 'imported') {
        Write-Output 'elevation_failed'
        return
    }

    $verifyStore = New-Object System.Security.Cryptography.X509Certificates.X509Store('Root', 'LocalMachine')
    $verifyStore.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadOnly)
    try {
        $verified = $verifyStore.Certificates | Where-Object { $_.Thumbprint -eq $Thumbprint }
        if ($verified) {
            Write-Output 'imported'
        } else {
            Write-Output 'elevation_failed'
        }
    } finally {
        $verifyStore.Close()
    }
} finally {
    Remove-Item -Path $scriptPath -ErrorAction SilentlyContinue
    Remove-Item -Path $statusPath -ErrorAction SilentlyContinue
    Remove-Item -Path $tempCertPath -ErrorAction SilentlyContinue
}
