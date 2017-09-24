Get-WmiObject -Class Win32_Product | Where-Object {$_.Name -like "*Google*"} | foreach-object -process {$_.Uninstall()}
