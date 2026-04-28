param(
    [Parameter(Mandatory = $true)]
    [string]$CertificatePath
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $CertificatePath)) {
    throw "Certificate path not found: $CertificatePath"
}

$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($CertificatePath)
$states = @()

foreach ($storeLocation in @('LocalMachine', 'CurrentUser')) {
    $store = New-Object System.Security.Cryptography.X509Certificates.X509Store('Root', $storeLocation)
    try {
        try {
            $store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadOnly)
        } catch [System.Security.Cryptography.CryptographicException] {
            $states += "${storeLocation}=unreadable"
            continue
        }

        $existing = $store.Certificates | Where-Object { $_.Thumbprint -eq $cert.Thumbprint }
        if ($existing) {
            $states += "${storeLocation}=present"
        } else {
            $states += "${storeLocation}=missing"
        }
    } finally {
        $store.Close()
    }
}

Write-Output ($states -join ';')
