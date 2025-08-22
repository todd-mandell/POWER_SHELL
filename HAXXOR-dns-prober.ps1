$nameserver = "IPADDRESS";
$oct12 =  "FIRST.TWOOCTETS."

#IF YOU ONLY NEED THE 4TH OCTET, ADD THE THIRD TO THE VARIABLE AND REMOVE THIS FOR LOOP FOR THE 3RD OCTET BELOW
For ($oct3=0; $oct3 -lt 255; $oct3++)
    {
    For ($oct4=0; $oct4 -lt 255; $oct4++)
        {write $($oct12 + $oct3 + $oct4) | out-file DNS-probe.txt -append -nonewline; nslookup $($oct3 + $oct4) $nameserver | findstr "Name" | out-file DNS-probe.txt -append 
    }
}
