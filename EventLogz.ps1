###lots of changes to this one coming soon! I made it so it time stamps the output filenames too for evidence

get-eventlog system -message "*power*" | out-file -width 200 c:\powerEvents.txt

Get-EventLog system -entrytype Error -Newest 20 | select Message
