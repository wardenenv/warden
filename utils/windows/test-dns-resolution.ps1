param(
    [Parameter(Mandatory = $true)]
    [string]$Hostname
)

$ErrorActionPreference = 'Stop'

try {
    $result = Resolve-DnsName -Name $Hostname -DnsOnly -ErrorAction Stop | Select-Object -First 1
    Write-Output 'State=resolved'

    if ($result.NameHost) {
        Write-Output "Result=$($result.NameHost)"
    } elseif ($result.IPAddress) {
        Write-Output "Result=$($result.IPAddress)"
    }
} catch {
    $message = $_.Exception.Message.Trim()
    Write-Output 'State=failed'
    Write-Output "Message=$message"
}
