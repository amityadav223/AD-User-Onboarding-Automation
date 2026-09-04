# Enterprise IT User Onboarding Automation Script
# Description: Automates bulk user creation in Windows Active Directory using a CSV input.

# Import the Windows Active Directory administration module
Import-Module ActiveDirectory

# Define paths and corporate environment configurations
$CSVPath = ".\new_users.csv"
$Domain = "company.local" 

# Verify if the source HR dataset exists before proceeding
if (Test-Path $CSVPath) {
    $Users = Import-Csv -Path $CSVPath
    Write-Host "[LOG] CSV file detected. Processing onboarding pipeline..." -ForegroundColor Cyan

    foreach ($User in $Users) {
        # Standardize corporate username format (e.g., rkumar)
        $SamAccountName = ($User.FirstName.Substring(0,1) + $User.LastName).ToLower()
        $UserPrincipalName = "$SamAccountName@$Domain"
        $DisplayName = "$($User.FirstName) $($User.LastName)"
        
        # Check if the identity profile already exists in the infrastructure
        $UserExists = Get-ADUser -Filter "SamAccountName -eq '$SamAccountName'"
        
        if (-not $UserExists) {
            # Define target Organizational Unit (OU) container path based on department
            $TargetOU = "OU=$($User.Department),DC=company,DC=local"
            
            # Generate a temporary secure password (User must reset this at first logon)
            $SecurePassword = ConvertTo-SecureString "Welcome@2026!" -AsPlainText -Force

            # Provision the new user profile with identity tags into Active Directory
            New-ADUser -Name $DisplayName `
                       -SamAccountName $SamAccountName `
                       -UserPrincipalName $UserPrincipalName `
                       -GivenName $User.FirstName `
                       -Surname $User.LastName `
                       -Title $User.Title `
                       -Department $User.Department `
                       -Path $TargetOU `
                       -AccountPassword $SecurePassword `
                       -ChangePasswordAtLogon $true `
                       -Enabled $true

            Write-Host "SUCCESS: Account provisioned for $DisplayName ($SamAccountName)" -ForegroundColor Green
        } else {
            Write-Host "WARNING: Profile conflict. User $SamAccountName already exists in directory." -ForegroundColor Yellow
        }
    }
    Write-Host "[LOG] Onboarding script run completed successfully." -ForegroundColor Cyan
} else {
    Write-Host "ERROR: Target dataset not located at $CSVPath" -ForegroundColor Red
}
