function Get-DirWritePermission{
<#

.SYNOPSIS
This script recursively searches a path to find writeable directories for non admin user.

.DESCRIPTION
A poweshell script that enumerate directories inside folders which are writable by non-admin users and print it out for the user.
 
.PARAMETER User
Username who's permissions should be checked

.PARAMETER Path
The path of the directory to be checked. Defaults to C:\windows\system32

.PARAMETER Confirm
Switch to confim write access by actually writing a file to the directory as the current user (You will have to impersonate other users to confirm their rights)

.EXAMPLE
PS C:\> . .\Get-DirWritePermission.ps1
PS C:\> Get-DirWritePermission -Username benjamin -Confirm

.LINK
https://sa1m0nz.wordpress.com/2018/01/26/enumerate-directories-inside-cwindowssystem32-which-are-writable-by-non-admin-users-powershell-for-pentesters-task-3/

.NOTES
This script has been created for completing the requirements of the SecurityTube PowerShell for Penetration Testers Certification Exam
http://www.securitytube-training.com/online-courses/powershell-for-pentesters/
Student ID: PSP-6248
#> 

[CmdletBinding()] Param(
        [Parameter(Mandatory = $true)]
        [Alias("Username")]
        [String]
        $User,

        [Parameter(Mandatory = $false)]
        [Alias('Location','Directory')]
        [String]
        $Path = "C:\windows\system32",

        [Parameter(Mandatory = $false)]
        [Switch]
        $Confirm
               
        )


$current = 0

$Directories = Get-ChildItem $Path -Recurse -Directory -ErrorAction SilentlyContinue| foreach {If ($_.psiscontainer) {$_.fullname}}
$ErrorActionPreference = 'SilentlyContinue'
$dirs = $Directories.Length
foreach ($dir in $directories )
    {
        Write-Progress -Activity "Search in Progress" -Status "$current/$dirs" -PercentComplete ($current/$dirs*100) -CurrentOperation $dir
        $current++
        $permissions = icacls $dir
        if ( ($permissions) -match $User){ 
            write-host ( $dir + " directory maybe writeable for user [ " + $User + "]" ) -ForegroundColor Yellow
            " "

                if ($confirm){
                "Confirming the write permission by creating a file.... `n "
                $check = $dir + "\check.txt"

                Try{
                [io.file]::OpenWrite($check).close()
                Write-Host "[+] Permission Confirmed! $User can write in: $dir" -foregroundColor Green
                #Deleting the file
                [io.file]::Delete($check)
                }

                Catch{
                Write-Host "[-] Permission could not be confimed" -foregroundColor Red
                }
            } }
    }
}
