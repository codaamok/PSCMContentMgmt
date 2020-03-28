function Get-DPContent {
    <#
    .SYNOPSIS
        Get all content distributed to a given distribution point by querying SMS_DPContentInfo class.
    .DESCRIPTION
        Get all content distributed to a given distribution point by querying SMS_DPContentInfo class.

        By default this function returns all content object types that match the given distribution point in the SMS_DPContentInfo class on the site server.

        You can filter the content objects by cumulatively using the available switches, e.g. using -Package -DriverPackage will return packages and driver packages.

        Properties returned are: ObjectName, Description, ObjectType, ObjectID, SourceSize, DistributionPoint.
    .PARAMETER DistributionPoint
        Name of distribution point (as it appears in ConfigMgr, usually FQDN) you want to query.
    .PARAMETER Package
        Filter on packages
    .PARAMETER DriverPackage
        Filter on driver packages
    .PARAMETER DeploymentPackage
        Filter on deployment packages
    .PARAMETER OperatingSystemImage
        Filter on Operating System images
    .PARAMETER OperatingSystemInstaller
        Filter on Operating System upgrade images
    .PARAMETER BootImage
        Filter on boot images
    .PARAMETER Application
        Filter on applications
    .PARAMETER SiteServer
        Query SMS_DPContentInfo on this server.
        
        It is not usually necessary to specify this parameter as importing the PSCMContentMgr module sets the $CMSiteServer variable which is the default value for this parameter.
        
        Specify this to query an alternative server, or if the module import process was unable to auto-detect and set $CMSiteServer.
    .PARAMETER SiteCode
        Site code of which the server specified by -SiteServer belongs to.
        
        It is not usually necessary to specify this parameter as importing the PSCMContentMgr module sets the $CMSiteCode variable which is the default value for this parameter.
        
        Specify this to query an alternative site, or if the module import process was unable to auto-detect and set $CMSiteCode.
    .EXAMPLE
        PS C:\> DP-Content -DistributionPoint dp.contoso.com -Package -Application

        Return all packages and applications found on dp.contoso.com.s
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [String]$DistributionPoint,

        [Parameter()]
        [Switch]$Package,

        [Parameter()]
        [Switch]$DriverPackage,
        
        [Parameter()]
        [Switch]$DeploymentPackage,
        
        [Parameter()]
        [Switch]$OperatingSystemImage,
        
        [Parameter()]
        [Switch]$OperatingSystemInstaller,
        
        [Parameter()]
        [Switch]$BootImage,
        
        [Parameter()]
        [Switch]$Application,

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
    }
    process {
        $Namespace = "ROOT/SMS/Site_{0}" -f $SiteCode
        $Query = "SELECT * FROM SMS_DPContentInfo WHERE NALPath like '%{0}%'" -f $DistributionPoint
    
        $conditions = switch ($true) {
            $Package                    { "ObjectType = '{0}'" -f [Int][SMS_DPContentInfo]"Package" }
            $DriverPackage              { "ObjectType = '{0}'" -f [Int][SMS_DPContentInfo]"DriverPackage" }
            $DeploymentPackage          { "ObjectType = '{0}'" -f [Int][SMS_DPContentInfo]"DeploymentPackage" }
            $OperatingSystemImage       { "ObjectType = '{0}'" -f [Int][SMS_DPContentInfo]"OperatingSystemImage" }
            $OperatingSystemInstaller   { "ObjectType = '{0}'" -f [Int][SMS_DPContentInfo]"OperatingSystemInstaller" }
            $BootImage                  { "ObjectType = '{0}'" -f [Int][SMS_DPContentInfo]"BootImage" }
            $Application                { "ObjectType = '{0}'" -f [Int][SMS_DPContentInfo]"Application" }
        }
    
        if ($conditions) { 
            $Query = "{0} AND ( {1} )" -f $Query, ([String]::Join(" OR ", $conditions)) 
        }
    
        Get-CimInstance -ComputerName $SiteServer -Namespace $Namespace -Query $Query -ErrorAction "Stop" | ForEach-Object {
            [PSCustomObject]@{
                PSTypeName        = "PSCMContentMgmt"
                ObjectName        = $_.Name
                Description       = $_.Description
                ObjectType        = [SMS_DPContentInfo]$_.ObjectType
                ObjectID          = $(if ($_.ObjectType -eq [SMS_DPContentInfo]"Application") {
                    ConvertTo-ModelNameCIID -ModelName $_.ObjectID
                }
                else {
                    $_.ObjectID
                })
                SourceSize        = $_.SourceSize
                DistributionPoint = $_.PSComputerName
            }
        }
    }
    end {

    }
}
