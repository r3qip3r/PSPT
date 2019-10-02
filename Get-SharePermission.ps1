
<#

.LINK
https://github.com/ahhh/PSSE/blob/master/Scan-Share-Permissions.ps1

 This blog post has been created for completing the requirements of the SecurityTube PowerShell for Penetration Testers Certification Exam: http://www.securitytube-training.com/online-courses/powershell-for-pentesters/

Student ID: PSP-6248 


#>


# Get list of servers from Active Directory 
$computernames = get-adcomputer -filter * |select  -ExpandProperty name;
$insecureshares = @()
# Loop through each server found 
foreach ($computer in $computernames) {
     try {
            write-host "Computername: " $computer -ForegroundColor Green
            $shares = Get-WMIObject win32_Share -ComputerName $Computer | select -ExpandProperty name
            }
             
    catch {
            Write-Host "Error: Could not access shares on $computer `n" -ForegroundColor red
            $shares = $null
            } 
  
foreach ($share in $shares) {  
    $acl = $null  
     
    $objShareSec = Get-WMIObject -Class Win32_LogicalShareSecuritySetting -Filter "name='$Share'"  -ComputerName $computer 
    try {  
        $SD = $objShareSec.GetSecurityDescriptor().Descriptor    
        foreach($ace in $SD.DACL){   
            $UserName = $ace.Trustee.Name      
            If ($ace.Trustee.Domain -ne $Null) {$UserName = "$($ace.Trustee.Domain)\$UserName"}    
            If ($ace.Trustee.Name -eq $Null) {$UserName = $ace.Trustee.SIDString }      
            if ($ace.Trustee.Name -eq "EveryOne" -and $ace.AccessMask -eq "2032127" -and $ace.AceType -eq 0) {$insecureshares +=  "\\$computer\$share - $($ace.trustee.name) - FullControl"}
				
            [Array]$ACL += New-Object Security.AccessControl.FileSystemAccessRule("$UserName", $ace.AccessMask, $ace.AceType)   
            
            } #end foreach ACE            
        } # end try  
    catch  
        { Write-Host "Share:"$share": Unable to obtain permissions" }  
    $ACL  
    Write-Host $('-' * 50)  
    } # end foreach $share
    if ($insecureshares) {
    write-host "Insecure shares found:" -ForegroundColor Green
    write-host $insecureshares 
    }
}
