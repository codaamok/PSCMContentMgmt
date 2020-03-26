function Get-DPContent {
    <#
    .SYNOPSIS
        Get all content distributed to a given distribution point by querying SMS_DPContentInfo class
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
