function ConvertTo-CIIDPackageId {
    <#
    .SYNOPSIS
        Get a Configuration Manager Application's PackageID property from the given CI_ID property
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$CIID,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$SiteServer,
        
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$SiteCode
    )
    begin {
        $Namespace = "ROOT/SMS/Site_{0}" -f $SiteCode
    }
    process {
        $Query = "SELECT * FROM SMS_ApplicationLatest WHERE CI_ID='{0}'" -f $CIID
        $Application = Get-CimInstance -ComputerName $SiteServer -Namespace $Namespace -Query $Query
        (Get-CimInstance $Application).PackageId
    }
    end {
    }
}
