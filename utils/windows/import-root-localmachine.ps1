#
# Performs the actual LocalMachine\Root import and writes a status token for
# the caller. This script is intended to run inside the elevated process.
#
param(
    [Parameter(Mandatory = $true)]
    [string]$CertificatePath,

    [Parameter(Mandatory = $true)]
    [string]$Thumbprint,

    [Parameter(Mandatory = $true)]
    [string]$StatusPath
)

$ErrorActionPreference = 'Stop'

function Test-AccessDeniedError {
    param($ErrorRecord)

    return (
        $ErrorRecord.Exception.HResult -eq -2147024891 -or
        $ErrorRecord.Exception.Message -match 'Access is denied'
    )
}

function Test-PolicyBlockedError {
    param($ErrorRecord)

    return $ErrorRecord.Exception.Message -match 'group policy|policy|administrator has blocked|managed by your organization'
}

$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($CertificatePath)
$store = New-Object System.Security.Cryptography.X509Certificates.X509Store('Root', 'LocalMachine')
try {
    $store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
} catch [System.Security.Cryptography.CryptographicException] {
    if (Test-AccessDeniedError $_) {
        Set-Content -Path $StatusPath -Value 'access_denied' -NoNewline
        exit 1
    }
    if (Test-PolicyBlockedError $_) {
        Set-Content -Path $StatusPath -Value 'policy_blocked' -NoNewline
        exit 1
    }
    Set-Content -Path $StatusPath -Value 'store_error' -NoNewline
    exit 1
}

try {
    try {
        $existing = $store.Certificates | Where-Object { $_.Thumbprint -eq $Thumbprint }
        if (-not $existing) {
            $staleWardenRoots = @(
                $store.Certificates | Where-Object {
                    $_.Thumbprint -ne $Thumbprint -and
                    $_.Subject -like '*O=Warden.dev*' -and
                    $_.Subject -like '*CN=Warden Proxy Local CA*'
                }
            )

            $store.Add($cert)

            foreach ($staleCert in $staleWardenRoots) {
                $store.Remove($staleCert)
            }
        }
    } catch [System.Security.Cryptography.CryptographicException] {
        if (Test-PolicyBlockedError $_) {
            Set-Content -Path $StatusPath -Value 'policy_blocked' -NoNewline
        } else {
            Set-Content -Path $StatusPath -Value 'store_error' -NoNewline
        }
        exit 1
    } catch {
        Set-Content -Path $StatusPath -Value 'store_error' -NoNewline
        exit 1
    }
} finally {
    $store.Close()
}

Set-Content -Path $StatusPath -Value 'imported' -NoNewline
