function Get-DPGroup {
    <#
    .SYNOPSIS
        Find distribution point group(s) by name. If nothing is returned, no match was found. % wildcard accepted.
    .DESCRIPTION
        Find distribution point group(s) by name. If nothing is returned, no match was found. % wildcard accepted.
    .PARAMETER Name
        Name of distribution point group(s) you want to search for. This does not have to be an exact match of how it appears in Configuration Manager, you can leverage the % wildcard character.
    .PARAMETER Exclude
        Name of distribution point group(s) you want to exclude from the search. This does not have to be an exact match of how it appears in Configuration Manager, you can leverage the % wildcard character.
    .PARAMETER SiteServer
        It is not usually necessary to specify this parameter as importing the PSCMContentMgr module sets the $CMSiteServer variable which is the default value for this parameter.
        
        Specify this to query an alternative server, or if the module import process was unable to auto-detect and set $CMSiteServer.
    .PARAMETER SiteCode
        Site code of which the server specified by -SiteServer belongs to.
        
        It is not usually necessary to specify this parameter as importing the PSCMContentMgr module sets the $CMSiteCode variable which is the default value for this parameter.
        
        Specify this to query an alternative site, or if the module import process was unable to auto-detect and set $CMSiteCode.
    .EXAMPLE
        PS C:\> Get-DP

    .EXAMPLE
        PS C:\> Get-DP -Name "SERVERA%", "SERVERB%" -Exclude "%CMG%"

    .EXAMPLE
        PS C:\> Get-DP | Get-DPDistributionStatus -DistributionFailed | Group-Object -Property Name

    #>
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String[]]$Name,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String[]]$Exclude,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]$SiteServer = $CMSiteServer,
        
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]$SiteCode = $CMSiteCode
    )
    begin {
        switch ($null) {
            $SiteCode {
                Write-Error -Message "Please supply a site code using the -SiteCode parameter" -Category "InvalidArgument" -ErrorAction "Stop"
            }
            $SiteServer {
                Write-Error -Message "Please supply a site server FQDN address using the -SiteServer parameter" -Category "InvalidArgument" -ErrorAction "Stop"
            }
        }
    }
    process {
        $Namespace = "ROOT/SMS/Site_{0}" -f $SiteCode
        $Query = "SELECT * FROM SMS_DistributionPointGroup"

        if ($PSBoundParameters.ContainsKey("Name")) {
            $DPGroups = foreach ($TargetDPGroup in $Name) {
                "Name LIKE '{0}'" -f $TargetDPGroup
            }

            $Query = "{0} WHERE ( {1} )" -f $Query, [String]::Join(" OR ", $DPGroups)
        }

        if ($PSBoundParameters.ContainsKey("Exclude")) { 
            $Exclusions = foreach ($Exclusion in $Exclude) {
                "(NOT Name LIKE '{0}')" -f $Exclusion
            }

            if ($Query -match "where") {
                # Already got a filter in the query, append to it with an AND operator
                $Query = "{0} AND {1}" -f $Query, [String]::Join(" AND ", $Exclusions)
            }
            else {
                # No filter currently in the query, add one
                $Query = "{0} WHERE {1}" -f $Query, [String]::Join(" AND ", $Exclusions) 

            }
        }
    
        Get-CimInstance -ComputerName $SiteServer -Namespace $Namespace -Query $Query
    }
    end {
    }
}