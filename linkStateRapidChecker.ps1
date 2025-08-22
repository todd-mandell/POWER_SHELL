$adapter = "Ethernet 2"
$x=1
while($x=1) {
$stat1 = Get-NetAdapter | where {$_.Name -like $adapter} | select Status
$outputz = $adapter + $stat1
if($stat1 -like "*Up*"){write-host $outputz -ForegroundColor Green } else {write-host $outputz -ForegroundColor Red}
				
				}
						
	
