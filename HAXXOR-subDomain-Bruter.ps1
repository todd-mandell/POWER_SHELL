$URLARRAY=get-content C:\wordlist-subdomains.txt
$domainName = "DOMAIN.COM"

ForEach($URL in $URLARRAY)
{
    $number =1
    if($number -eq 1)
    {
		$target = $URL + "." + $domainName
        $result = resolve-dnsname -name $target
        $output = $target + " " + $result
        write $result
        out-file c:\$domainName.txt -inputobject $result -append
    }
    else
    {	#doubles up on the other catches. nothing belongs in here
    }
}
