spps -name *google*,*chrome* -force
gwmi -Class Win32_Product | Where-Object {$_.Name -like "*Google*"} | foreach-object -process {$_.Uninstall()}
ri 'C:\Program Files (x86)\Google' -recurse
