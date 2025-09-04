#M365 Risky signin finder ver 1.05
Import-Module Microsoft.Graph.Identity.SignIns
connect-mgGraph -tenantID TENANTUUID -Scopes "IdentityRiskEvent.Read.All" -nowelcome
### future idea to revoke sessions would need a seperate scope. send the email alert to user and MSP and then revoke the user and change pw to random crap in the script a few seconds later to ensure delivery
# connect-mgGraph -Scopes "User.RevokeSessions.All"

# Email settings - in windows use stored creds again
$smtpServer = "SMTP-SERVER"
$smtpPort = 587
$from = "SMTP-FROM-EMAIL"
$to = "SMTP-TO-EMAIL"
$subject = "CUSTOMER Risky Sign-In Detected"
#remove these two lines for stored cred vault in windows plz - too many option sin linux to try
$smtpUser = "SMTPUSERNAME"
$smtpPass = "SMTPPASSWORD"

# path to the text file array collection thang - cross platform
$filePath = "C:\RISKYLOGINS.txt"

# create andor read the file into the array
if (Test-Path $filePath) {
    $alertedSignIns = Get-Content $filePath
} else {
    Write-Host "File not found. Creating a new one."
	echo "Begin" | set-content $filePath
    $alertedSignIns = @{}
}

# this is the array formatted by curly braces
 $alertedSignIns = @{}

write-host "CUSTOMERNAME-FOR-REFERENCE Risky-signin monitor active"

while ($true) {
    try {

        #get risky users 
		$riskyUsers = Get-MgRiskDetection

        #added text contents from previous logins to the active hashtable
        Get-Content $filePath | ForEach-Object { $alertedSignIns[$_] = $true }

        foreach ($user in $riskyUsers) {
        #original line changed by todd
        $matchText = $($user.UserPrincipalName) + "-" + $($user.IPAddress) + "-" + $($user.DetectedDateTime)

        if ($user.RiskState -ne "none" -and -not $alertedSignIns.ContainsKey($matchText)) {
                # Compose email body
                $body = @"
                    Risky sign-in detected for user: $($user.UserPrincipalName)
                    Risk Level: $($user.RiskLevel)
                    Risk State: $($user.RiskState)
                    IP Address: $($user.IPAddress)
                    Detected DateTime: $($user.DetectedDateTime) UTC

                    Reset the user's password, revoke all sign-ins, and investigate sign-in logs in Entra portal.
"@

                # Send first email about risk to 
                Send-MailMessage -From $from -To $to -Subject $subject -Body $body -SmtpServer $smtpServer -Port $smtpPort -UseSsl -Credential (New-Object System.Management.Automation.PSCredential($smtpUser, (ConvertTo-SecureString $smtpPass -AsPlainText -Force)))

				#store it and mark it as alerted already
                $alertedSignIns[$matchText] = $true

				# write it to the txt file
				write-host " NAMENAME - Detection!" $matchText
				Add-Content -path $filePath -value $matchText
            }
        }
    } catch {
        Write-Error "Error occurred: $_"
    }

    # Wait 1 minute before checking again
    Start-Sleep -Seconds 60
}






