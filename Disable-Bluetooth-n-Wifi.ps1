#May need to rename adapters using the line 2 code to find the adapters first, THEN fix up line 3 and run it
gwmi -Cl Win32_NetworkAdapter | select ServiceName
gwmi -Cl Win32_NetworkAdapter | Where { $_.ServiceName -like "BCM*" -or $_.ServiceName -like "bth*"} | Foreach { $_.Disable() }
