$UN = "Username";$FN = "FirstName";$LN = "LastName";
$FULLN = $FN + " " + $LN;$PlainPassword = get-date -format "MMMMFFF!";
$SecPW = $PlainPassword | ConvertTo-SecureString -AsPlainText -Force;
$Display = write "un " $UN "pw " $PlainPassword;write $Display;write $Display | out-file C:\NewADUsersLog.txt -Append;
new-aduser -name $FULLN -UserPrincipalName $UN -displayname $FULLN -samaccountname $UN -givenname $FN -surname $LN -AccountPassword $SecPW -ChangePasswordAtLogon 1 -Enabled 1
