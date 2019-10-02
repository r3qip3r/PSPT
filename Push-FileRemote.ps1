function Push-FileRemote {

    <#
    
    .SYNOPSIS
    Scripte to transfer a file using PowerShell Remoting
    
    .DESCRIPTION
    The script transfers a file from a local path to a PSremoting session
    
    .PARAMETER LocalFile
    
    
    .PARAMETER Target
    
    
    .PARAMETER RemoteFile
    
    
    .PARAMETER User
    The user for the PowerShell Remoting
    
    .EXAMPLE
    Push-Fileremote 

    .LINK
    https://stackoverflow.com/questions/10635238/send-files-over-pssession
    https://blogs.msdn.microsoft.com/luisdem/2016/08/31/powershell-how-to-copy-a-local-file-to-remote-machines/
    
    .NOTES
    This script has been created for completing the requirements of the SecurityTube PowerShell for Penetration Testers Certification Exam
    http://www.securitytube-training.com/online-courses/powershell-for-pentesters/
    Student ID: PSP-6248
    
    
    #>
    
    
    [CmdletBinding()] Param( 
    
            [Parameter(Mandatory = $true)]
            [String]
            $LocalFile,
            
            [Parameter(Mandatory = $true)]
            [String]
            $Target,
            
            [Parameter(Mandatory = $true)]
            [String]
            $RemoteFile,
            
            [Parameter(Mandatory = $true)]
            [String]
            $User
    )
    $abslocalpath = Resolve-Path $LocalFile
    
    try {
    $Session = New-PSSession -ComputerName $target -Credential $user -Name "Push-FileRemote" 
    $remotepath = Invoke-Command -Session $Session -ScriptBlock {Get-Location}
    Copy-Item -Path $abslocalpath -Destination $remotepath\$RemoteFile -ToSession $session
    
    Write-Host "File has been transferred and the session [ " ($session.name) " ] has been left open for your convenience!" -ForegroundColor Green
    
    }catch{
    Write-Host "File could not be transferred." -ForegroundColor Red
    }
    
    }
    
    
