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
Connect-MgGraph -Scopes "Calendars.ReadWrite"

Write-Host "Loading backup file..."
$events = Get-Content -Path $BackupPath | ConvertFrom-Json

Write-Host "Deleting existing events..."
$existing = Get-MgUserCalendarEvent -UserId $UserPrincipalName -All

foreach ($evt in $existing) {
    Remove-MgUserCalendarEvent -UserId $UserPrincipalName -EventId $evt.Id -Confirm:$false
}

Write-Host "Restoring events..."

foreach ($evt in $events) {
    $newEvent = @{
        Subject      = $evt.Subject
        Body         = $evt.Body
        Start        = $evt.Start
        End          = $evt.End
        Location     = $evt.Location
        Attendees    = $evt.Attendees
        IsAllDay     = $evt.IsAllDay
        Sensitivity  = $evt.Sensitivity
        Importance   = $evt.Importance
        Recurrence   = $evt.Recurrence
        ReminderMinutesBeforeStart = $evt.ReminderMinutesBeforeStart
    }

    New-MgUserCalendarEvent -UserId $UserPrincipalName -BodyParameter $newEvent | Out-Null
}

Write-Host "Restore complete."
