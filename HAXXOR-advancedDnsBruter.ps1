$sdARRAY=get-content C:\toolz\wordlist-subdomains-tiny.txt
#$indexARRAY=get-content C:\toolz\wordlist-subdomains-tiny.txt
$indexARRAY="","index.html","cgi-bin"
$urlHalf1= "https://"
$urlHalf2= ".DOMAIN.COM/"
$domainKEYWORD= "JUSTTHEDOMAIN-KEYWORD-FOR-LOGGING"

$outFileName="c:\dnsBruteResultsts-" + $domainKEYWORD + ".txt"

Foreach($index in $indexARRAY)
{
	Foreach($sd in $sdARRAY)
    {
		try
		{
			$url = $urlHalf1 + $sd + $urlHalf2 + $index
			invoke-webrequest $url -timeoutsec 1
		}
		catch
		{
			$errorText = $url + " - " + $_.Exception
			write $errorText
			write $errorText | out-file $outFileName -append
		}
	}
	catch
	{
		$errorText = $url + " - " + $_.Exception
		write $errorText
		write $errorText | out-file $outFileName -append
	}
}

   
