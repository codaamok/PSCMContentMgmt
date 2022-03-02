function ConvertTo-ModelNameCIID {
    <#
    .SYNOPSIS
        Get a Configuration Manager Application's CI_ID property from the given ModelName property
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$ModelName,

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
        $Query = "SELECT CI_ID FROM SMS_ApplicationLatest WHERE ModelName = '{0}'" -f $ModelName
        (Get-CimInstance -ComputerName $SiteServer -Namespace $Namespace -Query $Query).CI_ID
    }
    end {

    }
}
