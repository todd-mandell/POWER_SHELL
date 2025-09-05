# Define the date range for quarantine search
$startDate = Get-Date "2022-01-01"
$endDate = Get-Date "2022-02-01"

# Set output file path
$outputPath = "filePath"

# Retrieve and export quarantined messages
$allMessages = @()
$page = 1
$pageSize = 500

do {
    $messages = Get-QuarantineMessage -StartReceivedDate $startDate -EndReceivedDate $endDate `
        -PageSize $pageSize -Page $page `
        | Select-Object ReceivedTime, Type, SenderAddress, Subject, Expires

    $allMessages += $messages
    $page++
} while ($messages.Count -eq $pageSize)

# Export to CSV
$allMessages | Export-Csv -Path $outputPath -NoTypeInformation

Write-Host "Export complete. File saved to $outputPath"
