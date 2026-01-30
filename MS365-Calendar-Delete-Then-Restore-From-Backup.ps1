# Restore the signed-in user's primary calendar from backup

# --- Cross-platform file dialog ---
function Select-BackupFile {
    param(
        [string]$Title = "Select a JSON backup file"
    )

    $file = Get-ChildItem -Filter *.json | 
        Out-GridView -Title $Title -PassThru

    if (-not $file) {
        throw "No file selected."
    }

    return $file.FullName
}

# --- Retry wrapper for throttling ---
function Invoke-WithRetry {
    param(
        [scriptblock]$Script,
        [int]$MaxRetries = 5
    )

    $attempt = 0
    while ($true) {
        try {
            return & $Script
        }
        catch {
            if ($_.Exception.Response.StatusCode -eq 429 -and $attempt -lt $MaxRetries) {
                $retryAfter = $_.Exception.Response.Headers["Retry-After"]
                if (-not $retryAfter) { $retryAfter = 5 }
                Start-Sleep -Seconds $retryAfter
                $attempt++
            }
            else {
                throw $_
            }
        }
    }
}

# --- Main script ---
$BackupPath = Select-BackupFile

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force
}

Import-Module Microsoft.Graph

Write-Host "Connecting to Microsoft Graph..."
Connect-MgGraph -Scopes "Calendars.ReadWrite"

Write-Host "Loading backup file..."
$backup = Get-Content -Path $BackupPath | ConvertFrom-Json

Write-Host "Deleting existing events..."
$existing = Invoke-WithRetry { Get-MgMeCalendarEvent -All }

foreach ($evt in $existing) {
    Invoke-WithRetry {
        Remove-MgMeCalendarEvent -EventId $evt.Id -Confirm:$false
    }
}

$total = $backup.Count
$index = 0

Write-Host "Restoring events..."

foreach ($item in $backup) {
    $index++
    Write-Progress -Activity "Restoring calendar" -Status "Restoring event $index of $total" -PercentComplete (($index / $total) * 100)

    $evt = $item.Event
    $atts = $item.Attachments

    $newEventBody = @{
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
        Categories   = $evt.Categories
        OnlineMeetingUrl = $evt.OnlineMeetingUrl
        ReminderMinutesBeforeStart = $evt.ReminderMinutesBeforeStart
    }

    $newEvent = Invoke-WithRetry {
        New-MgMeCalendarEvent -BodyParameter $newEventBody
    }

    foreach ($att in $atts) {
        $attachmentBody = @{
            "@odata.type" = "#microsoft.graph.fileAttachment"
            Name          = $att.Name
            ContentType   = $att.ContentType
            ContentBytes  = $att.ContentBytes
            IsInline      = $att.IsInline
        }

        Invoke-WithRetry {
            New-MgMeEventAttachment -EventId $newEvent.Id -BodyParameter $attachmentBody
        }
    }
}

Write-Host "Restore complete."
