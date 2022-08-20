# ad footprinting living out the land using adsi

function Get-DefaultPasswordPolicy() {
    # get default password policy of specified domain using adsi

    param($domain)

    # load details using adsi accelerator
    $DomainObject = [ADSI]"LDAP://$domain"

    # get ticks per day / minute to convert timestamp to days
    $TicksPerDay = 864000000000
    $TicksPerMinute = 600000000
    
    # parse out desired properties into an object
    [pscustomobject]@{
        name                     = $($DomainObject.name)
        whenCreated              = $($DomainObject.whenCreated)
        lockoutThreshold         = $($DomainObject.lockoutthreshold.Value)
        pwdHistory               = $($DomainObject.pwdhistoryLength.Value)
        pwdProperties            = $($DomainObject.pwdhistoryLength.Value)
        maxAge                   = $($DomainObject.ConvertLargeIntegerToInt64($DomainObject.maxpwdage.value) / - $TicksPerDay)
        minAge                   = $($DomainObject.ConvertLargeIntegerToInt64($DomainObject.minpwdage.value) / - $TicksPerDay)
        lockoutDuration          = $($DomainObject.ConvertLargeIntegerToInt64($DomainObject.lockoutduration.value) / - $TicksPerMinute)
        lockoutObservationWindow = $($DomainObject.ConvertLargeIntegerToInt64($DomainObject.lockoutobservationWindow.value) / - $TicksPerMinute)
    }
}

function Get-AdGroup {
    #  get ad group in current domain using adsi

    param($adGroup)

    # set up searcher
    Add-Type -AssemblyName System.DirectoryServices.AccountManagement
    $context = [System.DirectoryServices.AccountManagement.ContextType]::Domain
    $group = [System.DirectoryServices.AccountManagement.GroupPrincipal]::FindByIdentity($context, $adGroup)
    
    # get filtered object
    $properties = @('samaccountname', 'name', 'enabled', 'passwordneverexpires')
    $group.GetMembers() | Select-Object $properties
}

function Get-DomainController() {
    # Get Domain Controller using adsi

    param($name)

    # setup searcher
    $type = [System.DirectoryServices.ActiveDirectory.DirectoryContextType]::DirectoryServer
    $context = New-Object -TypeName System.DirectoryServices.ActiveDirectory.DirectoryContext -ArgumentList $type, $name
    $dc = [System.DirectoryServices.ActiveDirectory.DomainController]::GetDomainController($context)
    
    # get filtered object
    $params = @('name', 'domain', 'ipaddress', 'sitename', 'osversion', 'roles', 'currenttime')
    $dc | Select-Object $params
}

function Get-StalePasswords() {
    # gets objects stale ad passwords using adsi
    # defaults to all enabled users
    param(
        $searchBase, 
        $days,
        $filter = 'objectClass=user',
        $pageSize = 500

    )
    
    # setup searcher
    $ADSearcher = New-Object DirectoryServices.DirectorySearcher -Property @{
        SearchRoot = "LDAP://$elevatedOU,$domain"
        
        # use ldap bitwise ANDing
        # 2 = do not included disabled objects
        Filter     = "(&($filter)(userAccountControl:1.2.840.113556.1.4.803:=2))"
        PageSize   = $pageSize 
    }

    # execute search
    $results = $ADSearcher.FindAll()
    
    # iterate across all returns objects
    $results | ForEach-Object {
        $user = $_.Properties
        
        # calculate password age
        $pwdlastset = [datetime]::FromFileTime($($user.pwdlastset))
        $age = (New-TimeSpan -Start $pwdlastset -End $(Get-Date) | 
            Select-Object days).days

        $lastLogon = [datetime]::FromFileTime($($user.lastlogontimestamp))

        [pscustomobject]@{
            displayname       = $($user.displayname)
            samaccountname    = $($user.samaccountname)
            userprincipalname = $($user.userprincipalname)
            passwordAge       = $age
            pwdlastset        = $pwdlastset
            lastLogon         = $lastLogon
            distinguishedname = $($user.distinguishedname)
            manager           = $($user.manager)
            description       = $($user.description)
            whenChanged       = [datetime]$($user.whenchanged)
            
        }
    } | 
    
    # filter objects whose passwords are older than days
    Where-Object { $_.passwordAge -gt $days } 
}

function Get-GPOs() {
    # get gpos using adsi

    param(
        $filter = '(objectClass=groupPolicyContainer)',
        $pageSize = 500
    )

    # setup searcher
    $GPOSearcher = New-Object DirectoryServices.DirectorySearcher -Property @{
        Filter   = $filter
        PageSize = $pageSize
    }
    
    # execute search
    $GPOSearcher.FindAll() | 

    # iterate through results, parse properties construct an object
    ForEach-Object {
        New-Object -TypeName PSCustomObject -Property @{
            'DisplayName'       = $_.properties.displayname -join ''
            'CommonName'        = $_.properties.cn -join ''
            'FilePath'          = $_.properties.gpcfilesyspath -join ''
            'DistinguishedName' = $_.properties.distinguishedname -join ''
            'WhenCreated'       = $_.properties.whencreated -join ''
        }
    }
}

function Get-StaleComputers() {
    # get stale computers using adsi
    # by default gets all enabled computer objects

    param(
        $days,
        $filter = 'objectCategory=computer',
        $pageSize = 500
    )

    # convert days to ad timestamp format for lastlogontimestamp
    $logondate = (Get-Date).adddays(-$days).ToFileTime()

    # set up searcher
    $de = New-Object DirectoryServices.DirectoryEntry('LDAP://rootDSE')
    $root = New-Object DirectoryServices.DirectoryEntry("LDAP://$($de.DefaultNamingContext)")
    $searcher = New-Object System.DirectoryServices.DirectorySearcher($root)
    $searcher.PageSize = $pageSize
    $searcher.PropertiesToLoad.AddRange(@('name'))

    # use ldap bitwise ANDing
    # 2 = do not included disabled objects
    $searcher.Filter = "(&($filter)(lastlogontimestamp>=$logondate)(!(userAccountcontrol:1.2.840.113556.1.4.803:=2)))"
    
    # run search
    $comps = $searcher.findall()
    $comps
}

function Get-KrbtgtInfo() {
    param($domains)

    # setup adsi search
    $ADForestDomainsItem = $($ADForestDomains | Where-Object { $null -eq $_.parent })
    $ADForestDomainsDN = 'DC=' + $ADForestDomainsItem.Name -Replace ('\.', ',DC=')
    $ADUserKRBSearch = New-Object DirectoryServices.DirectorySearcher([ADSI]'')
    $ADUserKRBSearch.SearchRoot = "LDAP://$ADForestDomainsDN"
    $ADUserKRBSearch.PageSize = 500
    $ADUserKRBSearch.Filter = '(&(objectCategory=User)(name=krbtgt))'
    
    # search adsi
    $KRBADInfo = $ADUserKRBSearch.FindAll()
    
    # format results
    [string]$KRBADInfopwdlastsetInt8 = $KRBADInfo.Properties.pwdlastset
    $KRBADInfopwdlastset = [DateTime]::FromFileTimeutc($KRBADInfopwdlastsetInt8)

    # output custom object
    [pscustomobject]@{
        name        = $($KRBADInfo.properties.name)
        whenCreated = $($KRBADInfo.properties.whencreated)
        memberOf    = $($KRBADInfo.properties.memberof)
        pwdLastSet  = $KRBADInfopwdlastset
    }
}

function Find-SearchPrincipalNames() {
    # Get SPNs
    # by default only gets SPN's of user objects

    param(
        $pageSize = 10000,
        $filter = "objectclass=user"
    )

    # setup adsi search
    $search = New-Object System.DirectoryServices.DirectorySearcher
    $search.SearchRoot = $(New-Object System.DirectoryServices.DirectoryEntry)
    $search.PageSize = $pageSize
    $search.Filter = "(&($filter)(objectcategory=user)(servicePrincipalName=*))"
    $search.SearchScope = 'Subtree'
    
    # Execute Search
    $results = $search.FindAll()
    
    # Get SPN values for each returned objects
    $results | ForEach-Object {
        $userEntry = $_.GetDirectoryEntry()
        $spns = $userEntry.servicePrincipalName
        $spnArray = $spns -split (',')
        $spnArray | ForEach-Object {
            [pscustomobject]@{
                service = $($_ -split ('/'))[0]
                name    = $($userEntry.name)
                spn     = $_
            }
        }
    } | Sort-Object service
}