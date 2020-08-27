function ConvertTo-PackageIDCIID {
    <#
    .SYNOPSIS
        Get a ConfigMgr Application's CI_ID property from the given PackageID property
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$PackageID,

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
        $Query = "SELECT SMS_ApplicationLatest.CI_ID 
        FROM SMS_ApplicationLatest
        WHERE SMS_ApplicationLatest.ModelName in (
            SELECT SMS_PackageStatusDistPointsSummarizer.SecureObjectID 
            FROM SMS_PackageStatusDistPointsSummarizer 
            WHERE PackageID = '{0}'
        )" -f $PackageID
        (Get-CimInstance -ComputerName $SiteServer -Namespace $Namespace -Query $Query).CI_ID
    }
    end {

    }
}
