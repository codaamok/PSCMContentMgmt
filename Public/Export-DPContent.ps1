function Export-DPContent {
    <#
    .SYNOPSIS
        Exports distribution point content to .pkgx files 
    .PARAMETER InputObject
        A PSObject type "PSCMContentMgmt" generated by Get-DPContent
    .PARAMETER DistributionPoint
        Name of distribution point (as it appears in ConfigMgr, usually FQDN) you want to export content from.
    .PARAMETER ObjectID
        Unique ID of the content object you want to export.

        For Applications the ID must be the CI_ID value whereas for all other content objects the ID is PackageID.

        When using this parameter you must also use ObjectType.
    .PARAMETER ObjectType
        Object type of the content object you want to export.

        Can be one of the following values: "Package", "DriverPackage", "DeploymentPackage", "OperatingSystemImage", "OperatingSystemInstaller", "BootImage", "Application".

        When using this parameter you must also use ObjectID.
    .PARAMETER Folder
        The target directory to store the generated .pkgx files in.
    .Parameter Force
        Specify this switch to overwrite .pkgx files if they already exist in the target directory from -Folder.
    .PARAMETER SiteServer
        Query SMS_DPContentInfo on this server.

        It is not usually necessary to specify this parameter as importing the PSCMContentMgr module sets the $CMSiteServer variable which is the default value for this parameter.

        Specify this to query an alternative server, or if the module import process was unable to auto-detect and set $CMSiteServer.
    .PARAMETER SiteCode
        Site code of which the server specified by -SiteServer belongs to.

        It is not usually necessary to specify this parameter as importing the PSCMContentMgr module sets the $CMSiteCode variable which is the default value for this parameter.

        Specify this to query an alternative site, or if the module import process was unable to auto-detect and set $CMSiteCode.
    .EXAMPLE
        PS C:\> Get-DPContent -DistributionPoint "dp1.contoos.com" | Export-DPContent -Folder "E:\prestaged" -Force

        Gathers all content objects on dp1.contoso.com and exports them to .pkgx files in E:\prestaged, overwriting any files that already exist with the same name.
    .EXAMPLE
        PS C:\> Export-DPContent -DistributionPoint "dp1.contoso.com" -ObjectID "P01000F6" -ObjectType "Package" -Folder "E:\prestaged"

        Exports package item P01000F6 from dp1.contoos.com and saves the exported .pkgx file in E:\prestaged.
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
        [ValidateSet("Package", "DriverPackage","DeploymentPackage","OperatingSystemImage","OperatingSystemInstaller","BootImage","Application")]
        [SMS_DPContentInfo]$ObjectType,

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
        
        $result = [ordered]@{ 
            ObjectID   = $InputObject.ObjectID
            ObjectType = $InputObject.ObjectType
        }

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
