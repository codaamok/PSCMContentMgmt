function Start-DPContentDistribution {
    <#
    .SYNOPSIS
        Distributes content from a given list of package IDs to a given distribution point
    .PARAMETER ObjectID
        For Applications, it must be of ModelName type whereas for everything else PackageID is fine.
    .NOTES
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName="InputObject")]
        [PSTypeName('PSCMContentMgmt')]
        [PSCustomObject]$InputObject,

        [Parameter(Mandatory, ParameterSetName="InputObject")]
        [Parameter(Mandatory, ParameterSetName="SpecifyProperties")]
        [Parameter(Mandatory, ParameterSetName="Folder")]
        [String]$DistributionPoint,

        [Parameter(Mandatory, ParameterSetName="SpecifyProperties")]
        [ValidateNotNullOrEmpty()]
        [String]$ObjectID,

        [Parameter(Mandatory, ParameterSetName="SpecifyProperties")]
        [ValidateSet("Package","DriverPackage","DeploymentPackage","OperatingSystemImage","OperatingSystemInstaller","BootImage","Application")]
        [SMS_DPContentInfo]$ObjectType,

        [Parameter(Mandatory, ParameterSetName="Folder")]
        [ValidateScript({
            if (!([System.IO.Directory]::Exists($_))) {
                throw "Invalid path or access denied"
            } elseif (!($_ | Test-Path -PathType Container)) {
                throw "Value must be a directory, not a file"
            } else {
                return $true
            }
        })]
        [String]$Folder,

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

        switch ($PSCmdlet.ParameterSetName) {
           "InputObject" { }
           "SpecifyProperties" {
                $InputObject = [PSCustomObject]@{
                    ObjectID          = $ObjectID
                    ObjectType        = $ObjectType
                }
            }
            "Folder" {
                $Files = Get-ChildItem -Path $Folder -Filter "*.pkgx"
            }
        }

        $OriginalLocation = (Get-Location).Path

        if ($null -eq (Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue)) {
            New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $SiteServer -ErrorAction Stop | Out-Null
        }

        Set-Location ("{0}:\" -f $SiteCode) -ErrorAction "Stop"
    }
    process {
        switch ($PScmdlet.ParameterSetName) {
            "Folder" {
                foreach ($File in $FIles) {
                    if ($File.Name -match "^(?<ObjectType>0|3|5|257|258|259|512)_(?<ObjectID>[A-Za-z0-9]+)\.pkgx$") {
                        $InputObject = [PSCustomObject]@{
                            ObjectID          = $Matches.ObjectID
                            ObjectType        = $Matches.ObjectType
                        }
    
                        $result = [ordered]@{ ObjectID = $InputObject.ObjectID }

                        $Command = 'Start-CMContentDistribution -{0} "{1}" -DistributionPointName "{2}" -ErrorAction "Stop"' -f [SMS_DPContentInfo_CMParameters][SMS_DPContentInfo]$InputObject.ObjectType, $InputObject.ObjectID, $DistributionPoint
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
                    else {
                        Write-Warning ("Skipping '{0}'" -f $File.Name)
                    }
                }
            }
            default {
                $result = [ordered]@{ ObjectID = $InputObject.ObjectID }
                $Command = 'Start-CMContentDistribution -{0} "{1}" -DistributionPointName "{2}" -ErrorAction "Stop"' -f [SMS_DPContentInfo_CMParameters][SMS_DPContentInfo]$InputObject.ObjectType, $InputObject.ObjectID, $DistributionPoint
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
        }
    }
    end {
        Set-Location $OriginalLocation
    }
}
