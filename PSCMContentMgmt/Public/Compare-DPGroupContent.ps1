function Compare-DPGroupContent {
    <#
    .SYNOPSIS
        Returns a list of content objects missing from the given target server compared to the source server.
    .PARAMETER Source
        Name of the referencing distribution point group you want to query.
    .PARAMETER Target
        Name of the differencing distribution point group you want to query.
    .PARAMETER SiteServer
        It is not usually necessary to specify this parameter as importing the PSCMContentMgr module sets the $CMSiteServer variable which is the default value for this parameter.

        Specify this to query an alternative server, or if the module import process was unable to auto-detect and set $CMSiteServer.
    .PARAMETER SiteCode
        Site code of which the server specified by -SiteServer belongs to.

        It is not usually necessary to specify this parameter as importing the PSCMContentMgr module sets the $CMSiteCode variable which is the default value for this parameter.
        
        Specify this to query an alternative site, or if the module import process was unable to auto-detect and set $CMSiteCode.
    .EXAMPLE
        PS C:\> Compare-DPGroupContent -Source "Asia DPs" -Target "Europe DPs"

        Return content objects which are missing from "Europe DPs" compared to "Asia DPs"
    .EXAMPLE
        PS C:\> Compare-DPGroupContent -Source "London DPs" -Target "Mancester DPs" | Start-DPGroupContentDistribution -DistributionPointGroup "Mancester DPs"

        Compares the missing content objects in group Manchester DPs compared to "London DPs", and distributes them to distribution point group Manchester DPs.
    .EXAMPLE
        PS C:\> Compare-DPGroupContent -Source "London DPs" -Target "Mancester DPs" | Remove-DPGroupContent 

        Compares the missing content objects in group Manchester DPs compared to "London DPs", and removes them from distribution point group "London DPs".

        Use -DistributionPointGroup with Remove-DPGroupContent to either explicitly target "London DPs" or some other group. In this example, "London DPs" is the implicit target distribution point group as it reads the DistributionPointGroup property return from Compare-DPGroupContent.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$Source,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$Target,

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
            Resolve-DPGroup -Name $Source -SiteServer $SiteServer -SiteCode $SiteCode
            Resolve-DPGroup -Name $Target -SiteServer $SiteServer -SiteCode $SiteCode
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
    process {
        $SourceContent = Get-DPGroupContent -DistributionPointGroup $Source -SiteServer $SiteServer -SiteCode $SiteCode
        $TargetContent = Get-DPGroupContent -DistributionPointGroup $Target -SiteServer $SiteServer -SiteCode $SiteCode
    
        Compare-Object -ReferenceObject @($SourceContent) -DifferenceObject @($TargetContent) -Property ObjectID -PassThru | ForEach-Object {
            if ($_.SideIndicator -eq "<=") {
                [PSCustomObject]@{
                    PSTypeName             = "PSCMContentMgmt"
                    ObjectName             = $_.ObjectName
                    Description            = $_.Description
                    ObjectType             = ([SMS_DPContentInfo]$_.ObjectType).ToString()
                    ObjectID               = $_.ObjectID
                    SourceSize             = $_.SourceSize
                    DistributionPointGroup = $_.DistributionPointGroup
                }  
            }
        }
    }
    end {
    }    
}