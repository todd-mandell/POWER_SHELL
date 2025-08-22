# Requires Microsoft Graph PowerShell SDK
Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
Connect-MgGraph -Scopes "Application.Read.All", "AuditLog.Read.All", "Directory.Read.All"

# Get all OAuth2 permission grants
$grants = Get-MgOauth2PermissionGrant -All

# Get all service principals (apps)
$apps = Get-MgServicePrincipal -All

# Define risky scopes to flag
$riskyScopes = @("Mail.ReadWrite", "Files.Read.All", "User.ReadWrite.All", "Calendars.ReadWrite", "Directory.Read.All")

# Join grants with app metadata
$riskyApps = foreach ($grant in $grants) {
    $app = $apps | Where-Object { $_.Id -eq $grant.ClientId }
    if ($app -and $riskyScopes | Where-Object { $grant.Scope -like "*$_*" }) {
        [PSCustomObject]@{
            AppName       = $app.DisplayName
            AppId         = $app.AppId
            Publisher     = $app.PublisherName
            ConsentType   = $grant.ConsentType
            Scope         = $grant.Scope
            GrantedTo     = $grant.PrincipalId
        }
    }
}

# Output risky apps
$riskyApps | Format-Table -AutoSize
