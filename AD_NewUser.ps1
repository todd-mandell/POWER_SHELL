$NewUserName = "User1000"
$PlainPassword = get-date -format "MMMMFFF!"
$SecurePassword = $PlainPassword | ConvertTo-SecureString -AsPlainText -Force 
$Display = write "UN " $NewUserName "PW " $PlainPassword;write $Display
write $Display | out-file C:\AD-logs\NewADUsersLog.log -Append
new-aduser $NewUserName -AccountPassword $SecurePassword -ChangePasswordAtLogon 1 -Enabled 1
