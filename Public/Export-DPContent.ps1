function Export-DPContent {
    <#
    .SYNOPSIS
        Exports distribution point content to .pkgx files 
    .PARAMETER ObjectID
        For Applications, it must be of ModelName type whereas for everything else PackageID is fine.
    #>
    [CmdletBinding(DefaultParameterSetName="InputObject")]
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
        [ValidateSet("Package","DriverPackage","DeploymentPackage","OperatingSystemImage","OperatingSystemInstaller","BootImage","Application")]
        [SMS_DPContentInfo]$ObjectType,

        [Parameter(ParameterSetName="SpecifyProperties")]
        [ValidateNotNullOrEmpty()]
        [Alias("Name")]
        [String]$ObjectName,

        [Parameter(Mandatory)]
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
        [Switch]$Force,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]$SiteServer = $CMSiteServer,
        
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]$SiteCode = $CMSiteCode
    )
    begin {
        if ($PSCmdlet.ParameterSetName -ne "InputObject") {
            $InputObject = [PSCustomObject]@{
                Name              = $ObjectName
                ObjectID          = $ObjectID
                ObjectType        = $ObjectType
                DistributionPoint = $DistributionPoint
            }
        }

        $OriginalLocation = (Get-Location).Path

        if($null -eq (Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue)) {
            New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $SiteServer -ErrorAction Stop | Out-Null
        }

        Set-Location ("{0}:\" -f $SiteCode) -ErrorAction "Stop"
    }
    process {
        if ($LastDP -ne $InputObject.DistributionPoint) {
            try {     
                Resolve-DP -DistributionPoint $InputObject.DistributionPoint
            }
            catch {
                Write-Error -ErrorRecord $_
                return
            }
        }
        else {
            $LastDP = $InputObject.DistributionPoint
        }

        $File = "{0}_{1}.pkgx" -f [int]$InputObject.ObjectType, $InputObject.ObjectID
        $Path = Join-Path -Path $Folder -ChildPath $File

        if (Test-Path $Path) {
            if ($Force.IsPresent) {
                Remove-Item -Path $Path -Force
            }
            else {
                Write-Warning ("File '{0}' already exists, use -Force to overwrite" -f $Path)
                return
            }
        }
        
        $result = [ordered]@{ ObjectID = $InputObject.ObjectID }

        $Command = 'Publish-CMPrestageContent -{0} "{1}" -DistributionPointName "{2}" -FileName "{3}"' -f [SMS_DPContentInfo_CMParameters][SMS_DPContentInfo]$InputObject.ObjectType, $InputObject.ObjectID, $InputObject.DistributionPoint, $Path
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
