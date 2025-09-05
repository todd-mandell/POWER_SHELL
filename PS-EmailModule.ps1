$smtpServer = "SMTPSERVER-HOSTNAME"
$smtpPort = 587
$from = "EMAIL"
$to = "EMAIL"
$subject = "SUBJECT"
$smtpUser = "USERNAME"
$smtpPass = "PASSWORD"

                # Compose email body
                $body = @"
                    Test Email Stuff
"@

# Send email
Send-MailMessage -From $from -To $to -Subject $subject -Body $body -SmtpServer $smtpServer -Port $smtpPort -UseSsl -Credential (New-Object System.Management.Automation.PSCredential($smtpUser, (ConvertTo-SecureString $smtpPass -AsPlainText -Force)))
#who cares if its deprecated, they havent replaced it yet anyway
