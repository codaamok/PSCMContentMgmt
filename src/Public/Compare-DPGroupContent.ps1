function Compare-DPGroupContent {
    <#
    .SYNOPSIS
        Returns a list of content objects missing from the given target distribution point group compared to the source distribution point group.
    .DESCRIPTION
        Returns a list of content objects missing from the given target distribution poiint group compared to the source distribution poiint group.

        This function calls Get-DPGroupContent for both -Source and -Target. The results are passed to Compare-Object. The reference object is -Source and the difference object is -Target.
    .PARAMETER Source
        Name of the referencing distribution point group you want to query.
    .PARAMETER Target
        Name of the differencing distribution point group you want to query.
    .PARAMETER SiteServer
        FQDN address of the site server (SMS Provider). 
        
        You only need to use this parameter once for any function of PSCMContentMgmt that also has a -SiteServer parameter. PSCMContentMgmt remembers the site server for subsequent commands, unless you specify the parameter again to change site server.
    .PARAMETER SiteCode
        Site code of which the server specified by -SiteServer belongs to.

        You only need to use this parameter once for any function of PSCMContentMgmt that also has a -SiteCode parameter. PSCMContentMgmt remembers the site code for subsequent commands, unless you specify the parameter again to change site code.
    .INPUTS
        This function does not accept pipeline input.
    .OUTPUTS
        System.Management.Automation.PSObject
    .EXAMPLE
        PS C:\> Compare-DPGroupContent -Source "Asia DPs" -Target "Europe DPs"

        Return content objects which are missing from Europe DPs compared to Asia DPs.
    .EXAMPLE
        PS C:\> Compare-DPGroupContent -Source "London DPs" -Target "Mancester DPs" | Start-DPGroupContentDistribution -DistributionPointGroup "Mancester DPs"

        Compares the missing content objects in group Manchester DPs compared to London DPs, and distributes them to distribution point group Manchester DPs.
    .EXAMPLE
        PS C:\> Compare-DPGroupContent -Source "London DPs" -Target "Mancester DPs" | Remove-DPGroupContent 

        Compares the missing content objects in group Manchester DPs compared to London DPs, and removes them from distribution point group London DPs.

        Use -DistributionPointGroup with Remove-DPGroupContent to either explicitly target London DPs or some other group. In this example, London DPs is the implicit target distribution point group as it reads the DistributionPointGroup passed through the pipeline.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$Source,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$Target,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]$SiteServer,
        
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]$SiteCode
    )
    begin {
        Set-SiteServerAndSiteCode -SiteServer $Local:SiteServer -SiteCode $Local:SiteCode

        try {
            Resolve-DPGroup -Name $Source -SiteServer $Script:SiteServer -SiteCode $Script:SiteCode
            Resolve-DPGroup -Name $Target -SiteServer $Script:SiteServer -SiteCode $Script:SiteCode
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
    process {
        $SourceContent = Get-DPGroupContent -DistributionPointGroup $Source -SiteServer $Script:SiteServer -SiteCode $Script:SiteCode
        $TargetContent = Get-DPGroupContent -DistributionPointGroup $Target -SiteServer $Script:SiteServer -SiteCode $Script:SiteCode
    
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