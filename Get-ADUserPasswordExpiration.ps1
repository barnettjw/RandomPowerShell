function Get-ADUserPasswordExpiration() {
    # Calculate days until password expiration
    # uses the AD property msDS-UserPasswordExpiryTimeComputed
    
    # Required PowerShell Module: ActiveDirectory
    
    param( [Parameter(ValueFromPipeline)][object]$users )
    
    $($users | ForEach-Object {
            $user = Get-ADUser $_.SamAccountName -Properties msDS-UserPasswordExpiryTimeComputed
            $passwordExpiryTime = [datetime]::FromFileTime($user.'msDS-UserPasswordExpiryTimeComputed')

            $user | Add-Member -MemberType NoteProperty `
                -Name 'PasswordExpirationDate' `
                -Value $passwordExpiryTime -Force
            $user
        })
}
