function Set-SiteServerAndSiteCode {
    param (
        [Parameter()]
        [String]$SiteServer,
        
        [Parameter()]
        [String]$SiteCode
    )


    if ([String]::IsNullOrWhiteSpace($Local:SiteServer) -And -not $Script:SiteServer) {
        # User has not yet used use a -SiteServer paramater from any of the functions, therefore prompt
        $Script:SiteServer = Read-Host -Prompt "Enter FQDN address of the site server (SMS Provider)"
    }
    elseif (-not [String]::IsNullOrWhiteSpace($Local:SiteServer) -And $Script:ShlinkServer -ne $Local:SiteServer) {
        # User has previously used a -SiteServer parameter and is using it right now, and its value is different to what was used last in any of the functions
        # In other words, it has changed and they wish to use a different server, and that new server will be used for subsequent calls unless they specify a different server again.
        $Script:SiteServer = $Local:SiteServer
    }

    if ([String]::IsNullOrWhitespace($Local:SiteCode) -And -not $Script:SiteCode) {
        # User has not yet used use a -SiteCode paramater from any of the functions, therefore prompt
        $Script:SiteCode = Read-Host -Prompt "Enter the site code"
    }
    elseif (-not [String]::IsNullOrWhiteSpace($Local:SiteCode) -And $Script:SiteCode -ne $Local:SiteCode) {
        # User has previously used a -SiteCode parameter and is using it right now, and its value is different to what was used last in any of the functions
        # In other words, it has changed - they wish to use a different site code, and that new site code will be used for subsequent calls unless they specify a different site code again.
        $Script:SiteCode = $Local:SiteCode
    } 
}