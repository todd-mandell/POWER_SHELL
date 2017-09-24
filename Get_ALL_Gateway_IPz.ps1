Get-WmiObject -Class win32_networkAdapterConfiguration | where { $_.defaultipgateway  -like '*.*' } | select defaultipgateway | Format-List 
