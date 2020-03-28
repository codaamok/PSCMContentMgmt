function Get-DPContentDistributionStatus {
    <#
    .SYNOPSIS
        Short description
    .DESCRIPTION
        Long description
    .EXAMPLE
        PS C:\> <example usage>
        Explanation of what the example does
    #>
    [CmdletBinding()]
    param (
        [ParameteR(Mandatory)]
        [String]$DistributionPoint,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]$SiteServer = $CMSiteServer,
        
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]$SiteCode = $CMSiteCode
    )
    begin {
        try {
            Resolve-DP -DistributionPoint $DistributionPoint
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }

        if($null -eq (Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue)) {
            New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $SiteServer -ErrorAction Stop | Out-Null
        }

        Set-Location ("{0}:\" -f $SiteCode) -ErrorAction "Stop"
    }
    process {
        $Namespace = "ROOT/SMS/Site_{0}" -f $SiteCode
        $Query = "SELECT * FROM SMS_PackageStatusDistPointsSummarizer WHERE NALPath like '%{0}%'" -f $DistributionPoint

        Get-CimInstance -ComputerName $SiteServer -Namespace $Namespace -Query $Query -ErrorAction "Stop" | Select-Object -Property @(
            @{Label="ObjectID";Expression={$_.PackageID}}
            @{Label="ObjectType";Expression={[SMS_PackageStatusDistPointsSummarizer_PackageType]$_.PackageType}}
            @{Label="DistributionPoint";Expression={$DistributionPoint}}
            SourceVersion
            @{Label="State";Expression={[SMS_PackageStatusDistPointsSummarizer_State]$_.State}}
        )
    }
    end {
        Set-Location $OriginalLocation
    }
}