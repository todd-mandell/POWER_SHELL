get-eventlog -logname "Application" -message "*ApplicationPartialName*" | out-file -width 200 c:\Application_Events.txt
