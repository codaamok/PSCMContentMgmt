function Get-DP {
    <#
    .SYNOPSIS
        Find distribution point(s) by name. If nothing is returned, no match was found. % wildcard accepted.
    .DESCRIPTION
        Find distribution point(s) by name. If nothing is returned, no match was found. % wildcard accepted.
    .PARAMETER Name
        Name of distribution point(s) you want to search for. This does not have to be an exact match of how it appears in Configuration Manager (usually FQDN), you can leverage the % wildcard character.
    .PARAMETER Exclude
        Name of distribution point(s) you want to exclude from the search. This does not have to be an exact match of how it appears in Configuration Manager (usually FQDN), you can leverage the % wildcard character.
    .PARAMETER SiteServer
        FQDN address of the site server (SMS Provider). 
        
        You only need to use this parameter once for any function of PSCMContentMgmt that also has a -SiteServer parameter. PSCMContentMgmt remembers the site server for subsequent commands, unless you specify the parameter again to change site server.
    .PARAMETER SiteCode
        Site code of which the server specified by -SiteServer belongs to.

        You only need to use this parameter once for any function of PSCMContentMgmt that also has a -SiteCode parameter. PSCMContentMgmt remembers the site code for subsequent commands, unless you specify the parameter again to change site code.
    .INPUTS
        This function does not accept pipeline input.
    .OUTPUTS
        Microsoft.Management.Infrastructure.CimInstance#SMS_DistributionPointInfo
    .EXAMPLE
        PS C:\> Get-DP

        Return all disttribution points within the site.
    .EXAMPLE
        PS C:\> Get-DP -Name "SERVERA%", "SERVERB%" -Exclude "%CMG%"

        Return distribution points which have a ServerName property starting with SERVERA or SERVERB, but excluding any that match CMG anywhere in its name.
    .EXAMPLE
        PS C:\> Get-DP | Get-DPDistributionStatus -DistributionFailed | Group-Object -Property Name

        Return all distribution points, their associated failed distribution tasks and group the results by distribution point now for an overview.
    .EXAMPLE
        PS C:\> Get-DP -Name "London%" | Get-DPContent

        Return all content objects found on distribution points where their ServerName starts with "London".
    #>
    [CmdletBinding()]
    [OutputType([Microsoft.Management.Infrastructure.CimInstance])]
    param (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String[]]$Name,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String[]]$Exclude,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]$SiteServer,
        
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]$SiteCode
    )
    begin {
        Set-SiteServerAndSiteCode -SiteServer $Local:SiteServer -SiteCode $Local:SiteCode
    }
    process {
        $Namespace = "ROOT/SMS/Site_{0}" -f $Script:SiteCode
        $Query = "SELECT * FROM SMS_DistributionPointInfo"

        if ($PSBoundParameters.ContainsKey("Name")) {
            $DistributionPoints = foreach ($TargetDP in $Name) {
                "ServerName LIKE '{0}'" -f $TargetDP
            }

            $Query = "{0} WHERE ( {1} )" -f $Query, [String]::Join(" OR ", $DistributionPoints)
        }

        if ($PSBoundParameters.ContainsKey("Exclude")) { 
            $Exclusions = foreach ($Exclusion in $Exclude) {
                "(NOT ServerName LIKE '{0}')" -f $Exclusion
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
    
        Get-CimInstance -ComputerName $Script:SiteServer -Namespace $Namespace -Query $Query
    }
    end {
    }
}
