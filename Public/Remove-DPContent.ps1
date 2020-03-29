function Remove-DPContent {
    <#
    .SYNOPSIS
        Remove objects from a distribution point
    .PARAMETER InputObject
        Description here
    .PARAMETER DistributionPoint
        Description here
    .PARAMETER ObjectID
        Description here
    .PARAMETER ObjectType
        Description here
    .EXAMPLE 
        PS C:\> 
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName="InputObject")]
        [PSTypeName('PSCMContentMgmt')]
        [PSCustomObject]$InputObject,

        [Parameter(Mandatory, ParameterSetName="SpecifyProperties")]
        [ValidateNotNullOrEmpty()]
        [String]$DistributionPoint,

        [Parameter(Mandatory, ParameterSetName="SpecifyProperties")]
        [ValidateNotNullOrEmpty()]
        [String]$ObjectID,

        [Parameter(Mandatory, ParameterSetName="SpecifyProperties")]
        [ValidateSet("Package", "DriverPackage","DeploymentPackage","OperatingSystemImage","OperatingSystemInstaller","BootImage","Application")]
        [SMS_DPContentInfo]$ObjectType
    )
    begin {

    }
    process {

    }
    end {
        
    }
}