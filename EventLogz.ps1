$Dait = get-date -format 'MM-dd-yyyy'
$Locale = 'c:\'
$RecoverString = 'get-eventlog -log "System" -message "*recover*" | select TimeGenerated,Message | out-file -width 200 ' + $Locale + 'recoveryEvents' + $Dait + '.txt'
$PowerString = 'get-eventlog -log "System" -message "*shutdown*" | select TimeGenerated,Message | out-file -width 200 ' + $Locale + 'powerEvents' + $Dait + '.txt'
$DNSString = 'get-eventlog -log "System" -message "*DNS*" | select TimeGenerated,Message | out-file -width 200 ' + $Locale + 'DNS-Events' + $Dait + '.txt'
$DHCPString = 'get-eventlog -log "System" -message "*dhcp*" | select TimeGenerated,Message | out-file -width 200 ' + $Locale + 'DHCP-Events' + $Dait + '.txt'
$DiskString = 'get-eventlog -log "System" -message "*disk*" | select TimeGenerated,Message | out-file -width 200 ' + $Locale + 'DISK-Events' + $Dait + '.txt'
iex $RecoverString
iex $PowerString
iex $DNSString
iex $DHCPString
iex $DiskString
