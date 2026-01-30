# Backup the signed-in user's primary calendar with file attachments

# --- Cross-platform file dialog ---
function Save-BackupFile {
    param(
        [string]$Title = "Choose where to save the backup"
    )

    $suggested = "CalendarBackup_{0:yyyy-MM-dd_HH-mm-ss}.json" -f (Get-Date)
    $path = Read-Host "$Title (enter path ending in .json)`nSuggested: $suggested"

    if (-not $path.EndsWith(".json")) {
        throw "Backup file must end with .json"
    }

    return $path
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
$BackupPath = Save-BackupFile

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force
}

Import-Module Microsoft.Graph

Write-Host "Connecting to Microsoft Graph..."
Connect-MgGraph -Scopes "Calendars.Read"

Write-Host "Retrieving events..."
$events = Invoke-WithRetry { Get-MgMeCalendarEvent -All }

$total = $events.Count
$index = 0

$backup = @()

foreach ($evt in $events) {
    $index++
    Write-Progress -Activity "Backing up calendar" -Status "Processing event $index of $total" -PercentComplete (($index / $total) * 100)

    $attachments = Invoke-WithRetry {
        Get-MgMeEventAttachment -EventId $evt.Id -All
    } | Where-Object { $_.'@odata.type' -eq "#microsoft.graph.fileAttachment" }

    $fileAttachments = foreach ($att in $attachments) {
        @{
            Name        = $att.Name
            ContentType = $att.ContentType
            ContentBytes = $att.ContentBytes
            Size        = $att.Size
            IsInline    = $att.IsInline
        }
    }

    $backup += @{
        Event       = $evt
        Attachments = $fileAttachments
    }
}

Write-Host "Saving backup to $BackupPath..."
$backup | ConvertTo-Json -Depth 20 | Out-File -FilePath $BackupPath -Encoding UTF8

Write-Host "Backup complete."
