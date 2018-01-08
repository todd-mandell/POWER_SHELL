$Exece = gci FOLDER -i EXECUTABLE* -r | sort-object -property @{Expression={$_.CreationTime}; Ascending=$true} | select-object -last 1;cmd /c $Exece
