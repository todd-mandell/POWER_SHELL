gci -i *PartialFileName* -r | foreach-object -process {gc $_ | out-file -append c:\SearchFilesContentsALL.txt}
