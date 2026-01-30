# Backup the signed-in user's primary calendar with file attachments
param(
    [Parameter(Mandatory=$true)]
    [string]$BackupPath
)

# Ensure Graph module is installed
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force
}

Import-Module Microsoft.Graph

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
