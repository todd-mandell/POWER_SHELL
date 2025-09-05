Connect-MgGraph -Scopes "Application.Read.All", "AuditLog.Read.All", "Directory.Read.All", "User.Read.All" -nowelcome

# Get all OAuth2 permission grants
$grants = Get-MgOauth2PermissionGrant -All

# Get all service principals (apps)
$apps = Get-MgServicePrincipal -All

# Define risky scopes to flag
$riskyScopes = @("User.ReadWrite.All","Mail.ReadWrite", "Files.Read.All", "User.ReadWrite.All", "Calendars.ReadWrite", "Directory.Read.All")

$commonScopes = @("User.Read", "openid", "profile", "email", "offline_access")

# Join grants with app metadata
$riskyApps = foreach ($grant in $grants) {
    $app = $apps | Where-Object { $_.Id -eq $grant.ClientId }
       
       #change the variable in THIS line to change from common to risky
		foreach ($scope in $commonScopes) { 

		if ($app -and $scope | Where-Object { $grant.Scope -like $scope }) {
		
        try {
            $user = Get-MgUser -UserId $grant.PrincipalId

        [PSCustomObject]@{
            AppName       = $app.DisplayName
            AppId         = $app.AppId
            Publisher     = $app.PublisherName
            ConsentType   = $grant.ConsentType
            Scope         = $grant.Scope
			GrantedTo   = $user.DisplayName
            UserEmail   = $user.UserPrincipalName

            }
            
       } catch {
            # If user lookup fails, still show basic info
            [PSCustomObject]@{
            AppName       = $app.DisplayName
            AppId         = $app.AppId
            Publisher     = $app.PublisherName
            ConsentType   = $grant.ConsentType
            Scope         = $grant.Scope
            GrantedTo     = $grant.PrincipalId
            GrantedUnknown   = "Unknown or Admin Consent"
				}
			}
        }
    }
}

# Output risky apps
$riskyApps | Format-Table -AutoSize

#write to file
$riskyApps | Format-Table -AutoSize | out-file -filepath riskyAppsFound.txt
