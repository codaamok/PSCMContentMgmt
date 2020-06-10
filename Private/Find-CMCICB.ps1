function Find-CMCICB {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ParameterSetName="ModelName")]
        [String]$ModelName,
        [Parameter(Mandatory, ParameterSetName="CI_ID")]
        [String]$CI_ID,
        [Parameter(Mandatory)]
        [Hashtable]$CimParams
    )
    $Query = "SELECT CI_ID,LocalizedDisplayName,CIType_ID FROM SMS_ConfigurationItemLatest WHERE {0} = '{1}'" -f $PSCmdlet.ParameterSetName, (Get-Variable -Name $PSCmdlet.ParameterSetName).Value
    Get-CimInstance -Query $Query @CimParams | Select-Object -Property @(
        @{Label="Name";Expression={$_.LocalizedDisplayName}}
        @{Label="Description";Expression={$_.LocalizedDescription}}
        @{Label="ObjectType";Expression={[SMS_ConfigurationItemLatest_CIType_ID]$_.CIType_ID}}
        "CI_ID"
    )
}