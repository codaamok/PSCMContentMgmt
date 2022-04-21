function Compare-DPContent {
    <#
    .SYNOPSIS
        Returns a list of content objects missing from the given target server compared to the source server.
    .DESCRIPTION
        Returns a list of content objects missing from the given target server compared to the source server.

        This function calls Get-DPContent for both -Source and -Target. The results are passed to Compare-Object. The reference object is -Source and the difference object is -Target.
    .PARAMETER Source
        Name of the referencing distribution point (as it appears in Configuration Manager, usually FQDN) you want to query.
    .PARAMETER Target
        Name of the differencing distribution point (as it appears in Configuration Manager, usually FQDN) you want to query.
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
        PS C:\> Compare-DPContent -Source "dp1.contoso.com" -Target "dp2.contoso.com"

        Return content objects which are missing from dp2.contoso.com compared to dp1.contoso.com.
    .EXAMPLE
        PS C:\> Compare-DPContent -Source "dp1.contoso.com" -Target "dp2.contoso.com" | Start-DPContentDistribution -DistributionPoint "dp2.contoso.com"

        Compares the missing content objects on dp2.contoso.com to dp1.contoso.com, and distributes them to dp2.contoso.com.
    .EXAMPLE
        PS C:\> Compare-DPContent -Source "dp1.contoso.com" -Target "dp2.contoso.com" | Remove-DPContent 

        Compares the missing content objects on dp2.contoso.com to dp1.contoso.com, and removes them from distribution point dp1.contoso.com.

        Use -DistributionPoint with Remove-DPContent to either explicitly target dp1.contoso.com or some other group. In this example, dp1.contoso.com is the implicit target distribution point group as it reads the DistributionPointGroup property passed through the pipeline.
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
            Resolve-DP -Name $Source -SiteServer $Script:SiteServer -SiteCode $Script:SiteCode
            Resolve-DP -Name $Target -SiteServer $Script:SiteServer -SiteCode $Script:SiteCode
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
    process {
        $SourceContent = Get-DPContent -DistributionPoint $Source -SiteServer $Script:SiteServer -SiteCode $Script:SiteCode
        $TargetContent = Get-DPContent -DistributionPoint $Target -SiteServer $Script:SiteServer -SiteCode $Script:SiteCode
    
        Compare-Object -ReferenceObject @($SourceContent) -DifferenceObject @($TargetContent) -Property ObjectID -PassThru | ForEach-Object {
            if ($_.SideIndicator -eq "<=") {
                [PSCustomObject]@{
                    PSTypeName        = "PSCMContentMgmt"
                    ObjectName        = $_.ObjectName
                    Description       = $_.Description
                    ObjectType        = ([SMS_DPContentInfo]$_.ObjectType).ToString()
                    ObjectID          = $_.ObjectID
                    SourceSize        = $_.SourceSize
                    DistributionPoint = $_.DistributionPoint
                }  
            }
        }
    }
    end {
    }    
}