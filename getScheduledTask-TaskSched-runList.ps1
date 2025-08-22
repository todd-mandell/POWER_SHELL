 get-scheduledtask|get-scheduledtaskinfo|where-object{$_.lastruntime -gt (get-date).addhours(-100)} | select TaskName,LastRunTime | sort { $_.LastRunTime }
