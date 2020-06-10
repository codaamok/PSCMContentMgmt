function Find-CMDeploymentType {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ParameterSetName="ModelName")]
        [String]$ModelName,
        [Parameter(Mandatory, ParameterSetName="CI_ID")]
        [String]$CI_ID,
        [Parameter(Mandatory)]
        [Hashtable]$CimParams
    )
    $Query = "SELECT AppModelName,CI_ID,LocalizedDisplayName FROM SMS_DeploymentType WHERE IsLatest = 'True' AND {0} = '{1}'" -f $PSCmdlet.ParameterSetNAme, (Get-Variable -Name $PSCmdlet.ParameterSetName).Value
    Get-CimInstance -Query $Query @CimParams | Select-Object -Property @(
        @{Label="Name";Expression={$_.LocalizedDisplayName}}
        @{Label="Description";Expression={$_.LocalizedDescription}}
        @{Label="ObjectType";Expression={"DeploymentType"}}
        "CI_ID"
        @{Label="AppCIID";Expression={ConvertTo-ModelNameCIID -ModelName $_.AppModelName -SiteServer $SiteServer -SiteCode $SiteCode}}
    )
}