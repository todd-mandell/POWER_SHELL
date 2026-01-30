param(
    [Parameter(Mandatory=$true)]
    [string]$UserPrincipalName,

    [Parameter(Mandatory=$true)]
    [string]$BackupPath
)

# Install module if missing
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force
}

Import-Module Microsoft.Graph

Write-Host "Connecting to Microsoft Graph..."
Connect-MgGraph -Scopes "Calendars.Read"

Write-Host "Retrieving calendar events for $UserPrincipalName..."

$events = Get-MgUserCalendarEvent -UserId $UserPrincipalName -All

Write-Host "Exporting $($events.Count) events to $BackupPath..."

$events | ConvertTo-Json -Depth 10 | Out-File -FilePath $BackupPath -Encoding UTF8

Write-Host "Backup complete."
