function Find-CMDriver {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ParameterSetName="ModelName")]
        [String]$ModelName,
        [Parameter(Mandatory, ParameterSetName="CI_ID")]
        [String]$CI_ID,
        [Parameter(Mandatory)]
        [Hashtable]$CimParams
    )
    $Query = "SELECT CI_ID,LocalizedDisplayName FROM SMS_Driver WHERE {0} = '{1}'" -f $PSCmdlet.ParameterSetNAme, (Get-Variable -Name $PSCmdlet.ParameterSetName).Value
    Get-Ciminstance -Query $Query @CimParams | Select-Object -Property @(
        @{Label="Name";Expression={$_.LocalizedDisplayName}}
        @{Label="Description";Expression={$_.LocalizedDescription}}
        @{Label="ObjectType";Expression={"Driver"}}
        "CI_ID"
    )
}