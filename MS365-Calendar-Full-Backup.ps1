# Backup the signed-in user's primary calendar with file attachments

function Save-BackupFile {
    $suggested = "CalendarBackup_{0:yyyy-MM-dd_HH-mm-ss}.json" -f (Get-Date)
    $path = Read-Host "Enter full path for backup file (must end in .json)`nSuggested: $suggested"

    if (-not $path.EndsWith(".json")) {
        throw "Backup file must end with .json"
    }

    return $path
}

function Invoke-WithRetry {
    param([scriptblock]$Script, [int]$MaxRetries = 5)

    $attempt = 0
    while ($true) {
        try { return & $Script }
        catch {
            $status = $null
            try { $status = $_.Exception.Response.StatusCode } catch {}

            if ($status -eq 429 -and $attempt -lt $MaxRetries) {
                $retryAfter = 5
                try { $retryAfter = $_.Exception.Response.Headers["Retry-After"] } catch {}
                Write-Host "Throttled. Retrying in $retryAfter seconds..."
                Start-Sleep -Seconds $retryAfter
                $attempt++
            }
            else { throw $_ }
        }
    }
}

$BackupPath = Save-BackupFile

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force
}
Import-Module Microsoft.Graph

Write-Host "Connecting to Microsoft Graph..."
Connect-MgGraph -Scopes "Calendars.Read"

# --- FIX: Get real user ID ---
$UserId = (Get-MgUser -UserId 'me').Id

Write-Host "Retrieving events..."
$events = Invoke-WithRetry { Get-MgUserEvent -UserId $UserId -All }

$total = $events.Count
$index = 0
$backup = @()

foreach ($evt in $events) {
    $index++

    Write-Progress `
        -Activity "Backing up calendar" `
        -Status ("Processing event {0} of {1}" -f $index, $total) `
        -PercentComplete (($index / $total) * 100)

    $attachments = Invoke-WithRetry {
        Get-MgUserEventAttachment -UserId $UserId -EventId $evt.Id -All
    } | Where-Object { $_.'@odata.type' -eq "#microsoft.graph.fileAttachment" }

    $fileAttachments = foreach ($att in $attachments) {
        @{
            Name         = $att.Name
            ContentType  = $att.ContentType
            ContentBytes = $att.ContentBytes
            Size         = $att.Size
            IsInline     = $att.IsInline
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
