function Find-CMApplication {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ParameterSetName="ModelName")]
        [String]$ModelName,
        [Parameter(Mandatory, ParameterSetName="CI_ID")]
        [String]$CI_ID,
        [Parameter(Mandatory)]
        [Hashtable]$CimParams
    )

    $Query = "SELECT CI_ID,LocalizedDisplayName,LocalizedDescription FROM SMS_ApplicationLatest WHERE {0} = '{1}'" -f $PSCmdlet.ParameterSetName, (Get-Variable -Name $PSCmdlet.ParameterSetName).Value
    Get-CimInstance -Query $Query @CimParams | Select-Object -Property @(
        @{Label="Name";Expression={$_.LocalizedDisplayName}}
        @{Label="Description";Expression={$_.LocalizedDescription}}
        @{Label="ObjectType";Expression={"Application"}}
        "CI_ID"
    )
}