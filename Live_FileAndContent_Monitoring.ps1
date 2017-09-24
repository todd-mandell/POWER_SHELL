cd \whatever Dir
For ($x=1; $x -lt 10000; $x++){gci *FILE* | foreach-object -process {invoke-command -scriptblock{Get-Date;gc $_} | out-file -append c:\FILE_Live-and-Contents.txt}}
