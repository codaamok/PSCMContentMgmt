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
        PS C:\> Get-DPContent -Package -DistributionPoint "dp1.contoso.com" | Remove-DPContent

        Removes all packages distributed to dp1.contoso.com.
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
        [SMS_DPContentInfo]$ObjectType,

        [Parameter()]
        [Bool]$Confirm = $true,

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
            Write-Error -ErrorRecord $_
            return
        }

        $OriginalLocation = (Get-Location).Path

        if($null -eq (Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue)) {
            New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $SiteServer -ErrorAction Stop | Out-Null
        }

        Set-Location ("{0}:\" -f $SiteCode) -ErrorAction "Stop"

        if ($PSCmdlet.ParameterSetName -ne "InputObject") {
            $InputObject = [PSCustomObject]@{
                ObjectID          = $ObjectID
                ObjectType        = $ObjectType
                DistributionPoint = $DistributionPoint
            }
        }
    }
    process {
        if ($Confirm -eq $true) {
            $Title = "Removing {0} from '{1}'" -f $InputObject.ObjectID, $DistributionPoint
            $Question = "`nDo you want to remove '{0}' from distribution point '{1}'?" -f $InputObject.ObjectID, $DistributionPoint
            $Choices = "&Yes", "&No"
            $Decision = $Host.UI.PromptForChoice($title, $question, $choices, 0)
            if ($Decision -eq 1) {
                return
            }
        }

        $result = [ordered]@{ ObjectID = $InputObject.ObjectID }
        
        $Command = 'Remove-CMContentDistribution -DistributionPointName "{0}" -{1} "{2}" -Force -ErrorAction "Stop"' -f $DistributionPoint, [SMS_DPContentInfo_CMParameters][SMS_DPContentInfo]$InputObject.ObjectType, $InputObject.ObjectID
        $ScriptBlock = [ScriptBlock]::Create($Command)
        try {
            Invoke-Command -ScriptBlock $ScriptBlock -ErrorAction "Stop"
            $result["Result"] = "Success"
        }
        catch {
            Write-Error -ErrorRecord $_
            $result["Result"] = "Failed: {0}" -f $_.Exception.Message
        }
        [PSCustomObject]$result
    }
    end {
        Set-Location $OriginalLocation
    }
}