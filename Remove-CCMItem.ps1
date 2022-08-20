function Remove-CCMItem(){
    # selectively clear a file from CCM cache on a SCCM client

    param($filename)

    [__comobject]$CCMComObject = New-Object -ComObject 'UIResource.UIResourceMgr'
    
    $dirs = $CCMComObject.GetCacheInfo().GetCacheElements() | 
    ForEach-Object { Get-ChildItem $_.location } | 
    Where-Object { $_.name -eq $filename}
 
    foreach ($dir in $dirs) {
        $CacheItem = $CCMComObject.GetCacheInfo().GetCacheElements() | 
        Where-Object { $dir.DirectoryName -eq $_.location }
        
        $CCMComObject.GetCacheInfo().DeleteCacheElement([string]$($CacheItem.CacheElementID))
    }
}