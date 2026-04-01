param(
    [Parameter(Mandatory = $true)]
    [string]$Title,

    [Parameter(Mandatory = $true)]
    [string]$Message,

    [ValidateSet('Info', 'Warning', 'Error')]
    [string]$Level = 'Info'
)

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$notifyIcon = New-Object System.Windows.Forms.NotifyIcon

try {
    $notifyIcon.Icon = switch ($Level) {
        'Warning' { [System.Drawing.SystemIcons]::Warning }
        'Error' { [System.Drawing.SystemIcons]::Error }
        default { [System.Drawing.SystemIcons]::Information }
    }
    $notifyIcon.BalloonTipIcon = switch ($Level) {
        'Warning' { [System.Windows.Forms.ToolTipIcon]::Warning }
        'Error' { [System.Windows.Forms.ToolTipIcon]::Error }
        default { [System.Windows.Forms.ToolTipIcon]::Info }
    }
    $notifyIcon.BalloonTipTitle = $Title
    $notifyIcon.BalloonTipText = $Message
    $notifyIcon.Visible = $true
    $notifyIcon.ShowBalloonTip(5000)
    Start-Sleep -Seconds 6
} finally {
    $notifyIcon.Dispose()
}
