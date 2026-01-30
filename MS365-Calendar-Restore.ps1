# Restore the signed-in user's primary calendar from backup
# with strict comparison, summary review, incremental restore,
# and fallback to full delete+restore.

function Select-BackupFile {
    $path = Read-Host "Enter full path to the backup JSON file (must end in .json)"

    if (-not (Test-Path $path)) {
        throw "File not found: $path"
    }

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

function Get-EventSignature {
    param($evt)

    return @{
        Subject   = $evt.Subject
        Body      = $evt.Body.Content
        Start     = $evt.Start.DateTime
        End       = $evt.End.DateTime
        Location  = $evt.Location.DisplayName
        AllDay    = $evt.IsAllDay
        Recurrence = ($evt.Recurrence | ConvertTo-Json -Depth 10)
        Attendees  = ($evt.Attendees | ConvertTo-Json -Depth 10)
        Categories = ($evt.Categories | Sort-Object | ConvertTo-Json)
        Reminder   = $evt.ReminderMinutesBeforeStart
        Importance = $evt.Importance
        Sensitivity = $evt.Sensitivity
    }
}

function Compare-Signatures {
    param($a, $b)

    if ($a.Count -ne $b.Count) { return $false }

    foreach ($key in $a.Keys) {
        if ($a[$key] -ne $b[$key]) { return $false }
    }

    return $true
}

# ---------------- MAIN SCRIPT ----------------

$BackupPath = Select-BackupFile

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force
}
Import-Module Microsoft.Graph

Write-Host "Connecting to Microsoft Graph..."
Connect-MgGraph -Scopes "Calendars.ReadWrite"

# FIX: Get real user ID
$UserId = (Get-MgUser -UserId 'me').Id

Write-Host "Loading backup file..."
$backup = Get-Content -Path $BackupPath | ConvertFrom-Json

Write-Host "Retrieving current events..."
$current = Invoke-WithRetry { Get-MgUserEvent -UserId $UserId -All }

# Build lookup tables
$backupLookup = @{}
$currentLookup = @{}

foreach ($item in $backup) {
    $sig = Get-EventSignature $item.Event
    $backupLookup[$sig.GetHashCode()] = $item
}

foreach ($evt in $current) {
    $sig = Get-EventSignature $evt
    $currentLookup[$sig.GetHashCode()] = $evt
}

# Determine differences
$toCreate = @()
$toDelete = @()
$toUpdate = @()

# Check for creates + updates
foreach ($key in $backupLookup.Keys) {
    if (-not $currentLookup.ContainsKey($key)) {
        # No matching event → create
        $toCreate += $backupLookup[$key]
    }
    else {
        # Matching signature exists → check for differences
        $backupEvt = $backupLookup[$key].Event
        $currentEvt = $currentLookup[$key]

        if (-not (Compare-Signatures (Get-EventSignature $backupEvt) (Get-EventSignature $currentEvt))) {
            $toUpdate += @{
                Backup  = $backupLookup[$key]
                Current = $currentLookup[$key]
            }
        }
    }
}

# Check for deletes
foreach ($key in $currentLookup.Keys) {
    if (-not $backupLookup.ContainsKey($key)) {
        $toDelete += $currentLookup[$key]
    }
}

# Summary
Write-Host ""
Write-Host "===== SUMMARY ====="
Write-Host "Events to create: $($toCreate.Count)"
Write-Host "Events to update: $($toUpdate.Count)"
Write-Host "Events to delete: $($toDelete.Count)"
Write-Host "===================="
Write-Host ""

$apply = Read-Host "Apply incremental changes? (Y/N)"
if ($apply -ne 'Y' -and $apply -ne 'y') {
    $fallback = Read-Host "Fallback to full delete + restore? (Y/N)"
    if ($fallback -ne 'Y' -and $fallback -ne 'y') {
        Write-Host "Aborting. No changes made."
        exit
    }

    Write-Host "Performing full delete + restore..."

    # Delete all
    foreach ($evt in $current) {
        Invoke-WithRetry {
            Remove-MgUserEvent -UserId $UserId -EventId $evt.Id -Confirm:$false
        }
    }

    # Restore all
    $total = $backup.Count
    $index = 0

    foreach ($item in $backup) {
        $index++
        Write-Progress -Activity "Restoring" -Status "$index of $total" -PercentComplete (($index/$total)*100)

        $evt = $item.Event
        $atts = $item.Attachments

        $newEvent = Invoke-WithRetry {
            New-MgUserEvent -UserId $UserId -BodyParameter $evt
        }

        foreach ($att in $atts) {
            Invoke-WithRetry {
                New-MgUserEventAttachment -UserId $UserId -EventId $newEvent.Id -BodyParameter @{
                    "@odata.type" = "#microsoft.graph.fileAttachment"
                    Name = $att.Name
                    ContentType = $att.ContentType
                    ContentBytes = $att.ContentBytes
                    IsInline = $att.IsInline
                }
            }
        }
    }

    Write-Host "Full restore complete."
    exit
}

# ---------------- INCREMENTAL RESTORE ----------------

Write-Host "Applying incremental changes..."

# Deletes
foreach ($evt in $toDelete) {
    Invoke-WithRetry {
        Remove-MgUserEvent -UserId $UserId -EventId $evt.Id -Confirm:$false
    }
}

# Updates (delete + recreate)
foreach ($pair in $toUpdate) {
    $currentEvt = $pair.Current
    $backupEvt  = $pair.Backup.Event
    $atts       = $pair.Backup.Attachments

    Invoke-WithRetry {
        Remove-MgUserEvent -UserId $UserId -EventId $currentEvt.Id -Confirm:$false
    }

    $newEvent = Invoke-WithRetry {
        New-MgUserEvent -UserId $UserId -BodyParameter $backupEvt
    }

    foreach ($att in $atts) {
        Invoke-WithRetry {
            New-MgUserEventAttachment -UserId $UserId -EventId $newEvent.Id -BodyParameter @{
                "@odata.type" = "#microsoft.graph.fileAttachment"
                Name = $att.Name
                ContentType = $att.ContentType
                ContentBytes = $att.ContentBytes
                IsInline = $att.IsInline
            }
        }
    }
}

# Creates
foreach ($item in $toCreate) {
    $evt = $item.Event
    $atts = $item.Attachments

    $newEvent = Invoke-WithRetry {
        New-MgUserEvent -UserId $UserId -BodyParameter $evt
    }

    foreach ($att in $atts) {
        Invoke-WithRetry {
            New-MgUserEventAttachment -UserId $UserId -EventId $newEvent.Id -BodyParameter @{
                "@odata.type" = "#microsoft.graph.fileAttachment"
                Name = $att.Name
                ContentType = $att.ContentType
                ContentBytes = $att.ContentBytes
                IsInline = $att.IsInline
            }
        }
    }
}

Write-Host "Incremental restore complete."
