function Get-InfoWMI {

[CmdletBinding()]
Param (

    [Parameter(Position = 0, Mandatory = $false)]
    [String]
    $OutputFile,

    [Parameter(Position = 1, Mandatory = $false)]
    [String]
    $WmiNamespace = 'root\cimv2',

    [Parameter(Position = 2, Mandatory = $false)]
    [String]
    $WmiClassName = 'Win32_SendInfo',

    [Parameter(Position = 3, Mandatory = $false)]
    [String]
    $WmiPropertyName = 'info',

    [Parameter(Position = 4, Mandatory = $false)]
    [Switch]
    $CleanUp
    
)

Write-verbose "Reading information from $WmiNamespace and $WmiClassName"
$EncodedValue = ([WmiClass] "$WmiNamespace`:$WmiClassName").Properties[$WmiPropertyName].Value

Write-Verbose "Decoding information."
$bytes = [System.Convert]::FromBase64String($EncodedValue)
$output = [System.Text.Encoding]::UTF8.GetString($bytes)

    if($OutputFile)
    {
    Write-Output "Writing output to $OutFile"
    Out-File -InputObject $output -FilePath $OutputFile -Encoding utf8
    }
    
    else
    {
    $Output
    }
    
    
    if ($CleanUp)
    {
    Write-Verbose "Removing $WmiClassName."
    Get-WmiObject -Namespace $WmiNamespace -Class $WmiClassName -List | Remove-WmiObject
    }
} 
       
