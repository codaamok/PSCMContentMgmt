function Get-DPContentDistributionStatus {
    <#
    .SYNOPSIS
        Retrieve the content distribution status of all objects for a distribution point
    .PARAMETER DistributionPoint
        Name of distribution point (as it appears in ConfigMgr, usually FQDN) you want to query.
    .PARAMETER SiteServer
        Query SMS_DPContentInfo on this server.

        It is not usually necessary to specify this parameter as importing the PSCMContentMgr module sets the $CMSiteServer variable which is the default value for this parameter.

        Specify this to query an alternative server, or if the module import process was unable to auto-detect and set $CMSiteServer.
    .PARAMETER SiteCode
        Site code of which the server specified by -SiteServer belongs to.

        It is not usually necessary to specify this parameter as importing the PSCMContentMgr module sets the $CMSiteCode variable which is the default value for this parameter.

        Specify this to query an alternative site, or if the module import process was unable to auto-detect and set $CMSiteCode.
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

        $OriginalLocation = (Get-Location).Path

        if($null -eq (Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue)) {
            [void](New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $SiteServer -ErrorAction "Stop")
        }

        Set-Location ("{0}:\" -f $SiteCode) -ErrorAction "Stop"
    }
    process {
        $Namespace = "ROOT/SMS/Site_{0}" -f $SiteCode
        $Query = "SELECT PackageID,PackageType,State,SourceVersion FROM SMS_PackageStatusDistPointsSummarizer WHERE ServerNALPath like '%{0}%'" -f $DistributionPoint

        # Add filters like in Get-DPContent

        Get-CimInstance -ComputerName $SiteServer -Namespace $Namespace -Query $Query -ErrorAction "Stop" | ForEach-Object {
            [PSCustomObject]@{
                PSTypeName        = "PSCMContentMgmt"
                ObjectID          = $_.PackageID
                ObjectName        = [SMS_PackageStatusDistPointsSummarizer_PackageType]$_.PackageType
                State             = [SMS_PackageStatusDistPointsSummarizer_State]$_.State
                SourceVersion     = $_.SourceVersion
                DistributionPoint = $DistributionPoint
            }
        }
    }
    end {
        Set-Location $OriginalLocation
    }
}