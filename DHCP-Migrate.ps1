Export-DhcpServer -ComputerName OLD_DHCP_SERVER_HOSTNAME -File "C:\DHCP-Config.xml"
Import-DhcpServer -ComputerName NEW_DHCP_SERVER_HOSTNAME -File "C:\DHCP-Config.xml" -backuppath "C:\Windows\System32\dhcp\backup\"
