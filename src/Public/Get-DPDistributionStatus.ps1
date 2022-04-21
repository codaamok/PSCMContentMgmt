function Get-DPDistributionStatus {
    <#
    .SYNOPSIS
        Retrieve the content distribution status of all content objects for a distribution point.
    .DESCRIPTION
        Retrieve the content distribution status of all content objects for a distribution point.
    .PARAMETER DistributionPoint
        Name of distribution point(s) (as it appears in Configuration Manager, usually FQDN) you want to query.
    .PARAMETER Distributed
        Filter on content objects in distributed state
    .PARAMETER DistributionPending
        Filter on content objects in distribution pending state
    .PARAMETER DistributionRetrying
        Filter on content objects in distribution retrying state
    .PARAMETER DistributionFailed
        Filter on content objects in distribution failed state
    .PARAMETER RemovalPending
        Filter on content objects in removal pending state
    .PARAMETER RemovalRetrying
        Filter on content objects in removal retrying state
    .PARAMETER RemovalFailed
        Filter on content objects in removal failed state
    .PARAMETER ContentUpdating
        Filter on content objects in content updating state
    .PARAMETER ContentMonitoring
        Filter on content objects in content monitoring state
    .PARAMETER SiteServer
        FQDN address of the site server (SMS Provider). 
        
        You only need to use this parameter once for any function of PSCMContentMgmt that also has a -SiteServer parameter. PSCMContentMgmt remembers the site server for subsequent commands, unless you specify the parameter again to change site server.
    .PARAMETER SiteCode
        Site code of which the server specified by -SiteServer belongs to.

        You only need to use this parameter once for any function of PSCMContentMgmt that also has a -SiteCode parameter. PSCMContentMgmt remembers the site code for subsequent commands, unless you specify the parameter again to change site code.
    .INPUTS
        System.String[]
    .OUTPUTS
        System.Management.Automation.PSObject
    .EXAMPLE
        PS C:\> Get-DPDistributionStatus -DistributionPoint "dp1.contoso.com"

        Gets the content distribution status for all content objects on dp1.contoso.com.
    .EXAMPLE
        PS C:\> Get-DPDistributionStatus -DistributionPoint "dp1.contoso.com" | Start-DPContentRedistribution

        Gets the content distribution status for content objects in DistributionFailed state on dp1.contoso.com and initiates redisitribution for each of those content objects.
    .EXAMPLE
        PS C:\> Get-DP | Get-DPDistributionStatus -DistributionFailed | Group-Object -Property DistributionPoint

        Return all distribution points, their associated failed distribution tasks and group the results by distribution point name for an overview.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Alias("Name", "ServerName")]
        [ParameteR(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [String[]]$DistributionPoint,

        [Parameter()]
        [Switch]$Distributed,

        [Parameter()]
        [Switch]$DistributionPending,

        [Parameter()]
        [Switch]$DistributionRetrying,

        [Parameter()]
        [Switch]$DistributionFailed,

        [Parameter()]
        [Switch]$RemovalPending,

        [Parameter()]
        [Switch]$RemovalRetrying,

        [Parameter()]
        [Switch]$RemovalFailed,

        [Parameter()]
        [Switch]$ContentUpdating,

        [Parameter()]
        [Switch]$ContentMonitoring,

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
        foreach ($TargetDP in $DistributionPoint) {
            switch ($true) {
                ($LastDP -ne $TargetDP) {
                    try {
                        Resolve-DP -Name $TargetDP -SiteServer $Script:SiteServer -SiteCode $Script:SiteCode
                    }
                    catch {
                        Write-Error -ErrorRecord $_
                        return
                    }
                    
                    $LastDP = $TargetDP
                }
                default {
                    $LastDP = $TargetDP
                }
            }

            $Namespace = "ROOT/SMS/Site_{0}" -f $Script:SiteCode
            $Query = "SELECT PackageID,PackageType,State,SourceVersion FROM SMS_PackageStatusDistPointsSummarizer WHERE ServerNALPath like '%{0}%'" -f $TargetDP
    
            $conditions = switch ($true) {
                $Distributed          { "State = '{0}'" -f [Int][SMS_PackageStatusDistPointsSummarizer_State]"DISTRIBUTED" }
                $DistributionPending  { "State = '{0}'" -f [Int][SMS_PackageStatusDistPointsSummarizer_State]"DISTRIBUTION_PENDING" }
                $DistributionRetrying { "State = '{0}'" -f [Int][SMS_PackageStatusDistPointsSummarizer_State]"DISTRIBUTION_RETRYING" }
                $DistributionFailed   { "State = '{0}'" -f [Int][SMS_PackageStatusDistPointsSummarizer_State]"DISTRIBUTION_FAILED" }
                $RemovalPending       { "State = '{0}'" -f [Int][SMS_PackageStatusDistPointsSummarizer_State]"REMOVAL_PENDING" }
                $RemovalRetrying      { "State = '{0}'" -f [Int][SMS_PackageStatusDistPointsSummarizer_State]"REMOVAL_RETRYING" }
                $RemovalFailed        { "State = '{0}'" -f [Int][SMS_PackageStatusDistPointsSummarizer_State]"REMOVAL_FAILED" }
                $ContentUpdating      { "State = '{0}'" -f [Int][SMS_PackageStatusDistPointsSummarizer_State]"CONTENT_UPDATING" }
                $ContentMonitoring    { "State = '{0}'" -f [Int][SMS_PackageStatusDistPointsSummarizer_State]"CONTENT_MONITORING" }
            }
    
            if ($conditions) {
                $Query = "{0} AND ( {1} )" -f $Query, ([String]::Join(" OR ", $conditions)) 
            }
    
            Get-CimInstance -ComputerName $Script:SiteServer -Namespace $Namespace -Query $Query | ForEach-Object {
                [PSCustomObject]@{
                    PSTypeName        = "PSCMContentMgmt"
                    ObjectID          = $(if ($_.PackageType -eq [SMS_PackageStatusDistPointsSummarizer_PackageType]"Application") { 
                        ConvertTo-PackageIDCIID -PackageID $_.PackageID -SiteServer $Script:SiteServer -SiteCode $Script:SiteCode
                    }
                    else {
                        $_.PackageID
                    })
                    ObjectType        = ([SMS_PackageStatusDistPointsSummarizer_PackageType]$_.PackageType).ToString()
                    State             = [SMS_PackageStatusDistPointsSummarizer_State]$_.State
                    SourceVersion     = $_.SourceVersion
                    DistributionPoint = $TargetDP
                }
            }
        }
    }
    end {
    }
}
