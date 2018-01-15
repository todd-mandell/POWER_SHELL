##### AD Server Creation entirely thru powershell with your DNS elsewhere or local resolution

#####Whatchya Got so far - also good to determine at the end if you're missing anything
Get-WindowsFeature | where {$_.Installed -eq 1}
Get-NetIPAddress | select InterfaceAlias,IPAddress

#####Commence Final Execution Block
workflow Get-AD-Ready {

$NuPCName = 'My-AD-Server';
$NuDomainName = 'Corp.NuDomain.Bidness';
$NuNetBiosName = 'NuNetBiosName';
$PlainPassword= 'Passwordio2';
$SafeModeAdminPW = $PlainPassword | ConvertTo-SecureString -AsPlainText -Force 

$NuIP = 'New-NetIPAdress -IPAddress 192.168.50.206 -InterfaceAlias Ethernet0';InlineScript {$NuIP};

rename-computer -NewName $NuPCName;IF ($_.RestartNeeded -eq "No") {Restart-Computer -wait} ELSE {"No Restart Needed"};

install-WindowsFeature AD-Domain-Services -IncludeManagementTools;IF ($_.RestartNeeded -eq "No") {Restart-Computer -wait} ELSE {"No Restart Needed"};

add-windowsfeature RSAT-AD-Tools;IF ($_.RestartNeeded -eq "No") {Restart-Computer -wait} ELSE {"No Restart Needed"};

$NuIMP = 'Import-Module ActiveDirectory,ADDSDeployment';InlineScript {$NuIMP};

add-windowsfeature -name ad-domain-services,dns,gpmc;IF ($_.RestartNeeded -eq "No") {Restart-Computer -wait} ELSE {"No Restart Needed"};

Install-ADDSForest -CreateDnsDelegation:$false -DatabasePath "C:\Windows\NTDS" -DomainMode "Win2012" -DomainName $NuDomainName -DomainNetbiosName $NuNetBiosName -ForestMode "Win2012" -InstallDns:$true -LogPath "C:\Windows\NTDS" -NoRebootOnCompletion:$false -SafeModeAdministratorPassword $SafeModeAdminPW -SysvolPath "C:\Windows\SYSVOL" -Force:$true;

}

##### See what you messed up when done
Get-EventLog system -entrytype Error -Newest 20 | select Message
Get-WindowsFeature | where {$_.Installed -eq 1}
