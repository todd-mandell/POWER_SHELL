Get-WmiObject -Class Win32_Product | Where-Object {$_.Name -like "*Google*"} | foreach-object -process {$_.Uninstall()}
##needs another line to delete the operational folder
#Shortened
gwmi Win32_Product | Where {$_.Name -like "*Google*"} | foreach -process {$_.Uninstall()}
