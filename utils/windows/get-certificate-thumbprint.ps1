param(
    [Parameter(Mandatory = $true)]
    [string]$CertificatePath
)

$ErrorActionPreference = 'Stop'

$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($CertificatePath)
Write-Output $cert.Thumbprint
