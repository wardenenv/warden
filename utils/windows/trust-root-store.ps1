param(
    [Parameter(Mandatory = $true)]
    [string]$CertificatePath,

    [Parameter(Mandatory = $true)]
    [ValidateSet('CurrentUser', 'LocalMachine')]
    [string]$StoreLocation
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

if (-not (Test-Path $CertificatePath)) {
    throw "Certificate path not found: $CertificatePath"
}

$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($CertificatePath)
$store = New-Object System.Security.Cryptography.X509Certificates.X509Store('Root', $StoreLocation)

try {
    try {
        $store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
    } catch [System.Security.Cryptography.CryptographicException] {
        if (Test-AccessDeniedError $_) {
            Write-Output 'access_denied'
            exit 0
        }
        if (Test-PolicyBlockedError $_) {
            Write-Output 'policy_blocked'
            exit 0
        }
        Write-Output 'store_error'
        exit 0
    }

    try {
        $existing = $store.Certificates | Where-Object { $_.Thumbprint -eq $cert.Thumbprint }
        if ($existing) {
            Write-Output 'present'
            exit 0
        }

        $staleWardenRoots = @(
            $store.Certificates | Where-Object {
                $_.Thumbprint -ne $cert.Thumbprint -and
                $_.Subject -like '*O=Warden.dev*' -and
                $_.Subject -like '*CN=Warden Proxy Local CA*'
            }
        )

        $store.Add($cert)

        foreach ($staleCert in $staleWardenRoots) {
            $store.Remove($staleCert)
        }

        if ($staleWardenRoots.Count -gt 0) {
            Write-Output 'replaced'
        } else {
            Write-Output 'imported'
        }
    } catch [System.Security.Cryptography.CryptographicException] {
        if (Test-AccessDeniedError $_) {
            Write-Output 'access_denied'
        } elseif (Test-PolicyBlockedError $_) {
            Write-Output 'policy_blocked'
        } else {
            Write-Output 'store_error'
        }
    } catch {
        Write-Output 'store_error'
    }
} finally {
    $store.Close()
}
