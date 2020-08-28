function Get-DPGroupContent {
    <#
    .SYNOPSIS
        Get all content distributed to a given distribution point group by querying the SMS_DPGroupContentInfo.
    .DESCRIPTION
        Get all content distributed to a given distribution point group by querying the SMS_DPGroupContentInfo.

        By default this function returns all content object types that match the given distribution point group in the SMS_DPGroupContentInfo class on the site server.

        You can filter the content objects by cumulatively using the available switches, e.g. using -Package -DriverPackage will return packages and driver packages.

        Properties returned are: ObjectName, Description, ObjectType, ObjectID, SourceSize, DistributionPoint.
    .PARAMETER DistributionPointGroup
        Name of distribution point group you want to query.
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
        It is not usually necessary to specify this parameter as importing the PSCMContentMgr module sets the $CMSiteServer variable which is the default value for this parameter.
        
        Specify this to query an alternative server, or if the module import process was unable to auto-detect and set $CMSiteServer.
    .PARAMETER SiteCode
        Site code of which the server specified by -SiteServer belongs to.
        
        It is not usually necessary to specify this parameter as importing the PSCMContentMgr module sets the $CMSiteCode variable which is the default value for this parameter.
        
        Specify this to query an alternative site, or if the module import process was unable to auto-detect and set $CMSiteCode.
    .EXAMPLE
        PS C:\> Get-DPGroupContent -DistributionPointGroup "Asia DPs" -Package -Application

        Return all packages and applications found in the distribution point group "Asia DPs"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$DistributionPointGroup,

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
        switch ($null) {
            $SiteCode {
                Write-Error -Message "Please supply a site code using the -SiteCode parameter" -Category "InvalidArgument" -ErrorAction "Stop"
            }
            $SiteServer {
                Write-Error -Message "Please supply a site server FQDN address using the -SiteServer parameter" -Category "InvalidArgument" -ErrorAction "Stop"
            }
        }
        
        try {
            Resolve-DPGroup -Name $DistributionPointGroup -SiteServer $SiteServer -SiteCode $SiteCode
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }        
    }
    process {
        $Namespace = "ROOT/SMS/Site_{0}" -f $SiteCode
        $Query = "SELECT * 
        FROM SMS_DPGroupContentInfo 
        WHERE SMS_DPGroupContentInfo.GroupID in (
            SELECT SMS_DPGroupInfo.GroupID
            FROM SMS_DPGroupInfo
            WHERE Name = '{0}'
        )" -f $DistributionPointGroup
    
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
    
        Get-CimInstance -ComputerName $SiteServer -Namespace $Namespace -Query $Query | ForEach-Object {
            [PSCustomObject]@{
                PSTypeName             = "PSCMContentMgmt"
                ObjectName             = $_.Name
                Description            = $_.Description
                ObjectType             = ([SMS_DPContentInfo]$_.ObjectType).ToString()
                ObjectID               = $(if ($_.ObjectType -eq [SMS_DPContentInfo]"Application") {
                    ConvertTo-ModelNameCIID -ModelName $_.ObjectID -SiteServer $SiteServer -SiteCode $SiteCode
                }
                else {
                    $_.ObjectID
                })
                SourceSize             = $_.SourceSize
                DistributionPointGroup = $DistributionPointGroup
            }
        }
    }
    end {
    }
}
