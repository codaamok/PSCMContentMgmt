function Get-DPGroupContent {
    <#
    .SYNOPSIS
        Get all content distributed to a given distribution point group.
    .DESCRIPTION
        Get all content distributed to a given distribution point group.

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
        PS C:\> Get-DPGroupContent -DistributionPointGroup "Asia DPs" -Package -Application

        Return all packages and applications found in the distribution point group "Asia DPs"
    .EXAMPLE
        PS C:\> Get-DPGroup -Name "All DPs" | Get-DPGroupContent

        Get all the content associated with the distribution point group "All DPs".
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Alias("Name")]
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [String[]]$DistributionPointGroup,

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
        [String]$SiteServer,
        
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]$SiteCode
    )
    begin {
        Set-SiteServerAndSiteCode -SiteServer $Local:SiteServer -SiteCode $Local:SiteCode
    }
    process {
        foreach ($TargetDPGroup in $DistributionPointGroup) {
            switch ($true) {
                ($LastDPGroup -ne $TargetDPGroup) {
                    try {
                        Resolve-DPGroup -Name $TargetDPGroup -SiteServer $Script:SiteServer -SiteCode $Script:SiteCode
                    }
                    catch {
                        Write-Error -ErrorRecord $_
                        return
                    }

                    $LastDPGroup = $TargetDPGroup
                }
                default {
                    $LastDPGroup = $TargetDPGroup
                }
            }

            $Namespace = "ROOT/SMS/Site_{0}" -f $Script:SiteCode
            $Query = "SELECT * 
            FROM SMS_DPGroupContentInfo 
            WHERE SMS_DPGroupContentInfo.GroupID in (
                SELECT SMS_DPGroupInfo.GroupID
                FROM SMS_DPGroupInfo
                WHERE Name = '{0}'
            )" -f $TargetDPGroup
        
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
        
            Get-CimInstance -ComputerName $Script:SiteServer -Namespace $Namespace -Query $Query | ForEach-Object {
                [PSCustomObject]@{
                    PSTypeName             = "PSCMContentMgmt"
                    ObjectName             = $_.Name
                    Description            = $_.Description
                    ObjectType             = ([SMS_DPContentInfo]$_.ObjectType).ToString()
                    ObjectID               = $(if ($_.ObjectType -eq [SMS_DPContentInfo]"Application") {
                        ConvertTo-ModelNameCIID -ModelName $_.ObjectID -SiteServer $Script:SiteServer -SiteCode $Script:SiteCode
                    }
                    else {
                        $_.ObjectID
                    })
                    SourceSize             = $_.SourceSize
                    DistributionPointGroup = $TargetDPGroup
                }
            }
        }
    }
    end {
    }
}
