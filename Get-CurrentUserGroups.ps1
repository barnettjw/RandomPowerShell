function Get-CurrentUserGroups(){
    # gets the ad groups of the current user

    param( $userName = $env:USERNAME  )
  
    Add-Type -AssemblyName System.DirectoryServices.AccountManagement            
    $context = [System.DirectoryServices.AccountManagement.ContextType]::Domain            
    $user = [System.DirectoryServices.AccountManagement.Principal]::FindByIdentity($context, $userName)           
    $user.GetGroups() | Select-Object name | Sort-Object
}