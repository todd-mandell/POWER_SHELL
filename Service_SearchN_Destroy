gsv | Where-Object {$_.DisplayName -like "*ServicePartialName*"} | foreach-object -process {Stop-Service $_.Name -force}
