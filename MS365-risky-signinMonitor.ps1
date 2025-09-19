#M365 Risky signin finder ver 1.05
Import-Module Microsoft.Graph.Identity.SignIns
connect-mgGraph -tenantID TENANTUUID -Scopes "IdentityRiskEvent.Read.All", "AuditLog.Read.All", "User.Read.All" -nowelcome
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
		#starts delay timer here
        $schtart = get-date
        
        #get risky users 
		$riskyUsers = Get-MgRiskDetection

        #added text contents from previous logins to the active hashtable
        Get-Content $filePath | ForEach-Object { $alertedSignIns[$_] = $true }

        foreach ($user in $riskyUsers) {
        
			#original line changed by todd
			$matchText = $($user.UserPrincipalName) + "-" + $($user.IPAddress) + "-" + $($user.DetectedDateTime)

			if ($user.RiskState -ne "none" -and -not $alertedSignIns.ContainsKey($matchText)) {
        
				#Then grab all the other data to investigate via the same email
				
				$UserPrincipalName = $($user.UserPrincipalName)
				$MGUser = Get-MgUser -UserId $UserPrincipalName
				$MGUserId = $MGUser.Id
				
				#event timer1
				$schtop = get-date
                $detectionEST = $user.DetectedDateTime.AddHours(-5)
				$detectionTimeDate = $schtop - $detectionEST
				$detectionLapse = "{0} DAYS and {1:hh\:mm\:ss} Hours Minutes Seconds" -f $detectionTimeDate.Days, $detectionTimeDate
				
				# Calculate time range: 1 week before attack
				$EndDateTime = Get-Date
				$detectionDays = -$detectionTimeDate.Days - 7
				$StartDateTime = $EndDateTime.AddDays($detectionDays)
				
				# get the actions
				$AuditLogDirectory = Get-MgAuditLogDirectoryAudit -All | Where-Object {
					#$_.InitiatedBy.User.UserPrincipalName -eq $UserPrincipalName -and
					$_.InitiatedBy.User.Id -eq $MGUserId -eq $UserPrincipalName -and
					$_.ActivityDateTime -ge $StartDateTime -and
					$_.ActivityDateTime -le $EndDateTime
				}

				#get the signin logs
				$AuditLogSignins = Get-MgAuditLogSignIn -top 2000 -All | Where-Object {
					$_.UserId -eq $MGUserId -and
					$_.CreatedDateTime -ge $StartDateTime -and
					$_.CreatedDateTime -le $EndDateTime
				}
				#script timer2
				$schtop2 = Get-Date
				$elapsed = $schtop2 - $schtart
				$formatted = $elapsed.ToString("hh\:mm\:ss") 
  
                # Compose email body
                $body = @"
DETECTION SUMMARY:

	Risky sign-in detected for user: $($user.UserPrincipalName)
    Risk Level: $($user.RiskLevel)
    Risk State: $($user.RiskState)
    IP Address: $($user.IPAddress)
    Country of Origin: $($user.Location.CountryOrRegion)
    Detected DateTime: $($user.DetectedDateTime) UTC

    Reset the user's password, revoke all sign-ins, reset MFA, delete legacy APP passwords, check for connectors, and investigate sign-in logs in Entra portal.

TECHNICAL INFOMATION:

	Estimated Elapsed Time from Detection to Reporting - $($detectionLapse)
	Estimated Latency from Script Reporting HH:MM:SS - $($formatted)
                    
	Virustotal Link: https://www.virustotal.com/gui/ip-address/$($user.IPAddress)/details
	Talos Intel Link: https://www.talosintelligence.com/reputation_center/lookup?search=$($user.IPAddress)


	Audit Log Directory Actions for the user:
$($AuditLogDirectory | select ActivityDateTime, ActivityDisplayName, @{Name='IPAddress'; Expression={ $_.InitiatedBy.User.IPAddress }}, Result, Category  | Format-Table -AutoSize | out-string )


	Audit Log Sign-Ins For the user:
$($AuditLogSignins | select CreatedDateTime, AppDisplayName, IPAddress ,  @{Name='Country'; Expression={ $_.Location.CountryOrRegion  }}, ConditionalAccessStatus, RiskEventTypes, @{Name='Details'; Expression={ $_.Status.AdditionalDetails  }} | Format-Table -AutoSize | out-string -Width 220 )

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






