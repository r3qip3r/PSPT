function Start-SimpleWebServer {

<#
.Synopsis
   A very simple webserver to upload, download or list files

.DESCRIPTION
   This webserver could be used to transfer files during a pentest. 

.PARAMETER hostname
The hostname of the server.

.PARAMETER port
The TCP port to listen on.

.PARAMETER WebRoot
The webroot of the server - defaults to the current working directory.


.EXAMPLE
 
    Start-SimpleWebServer -Port 9999

.LINK
This script relies heavily code and inspiration from:
https://github.com/tubesurf/PSPT/blob/master/7-http-web-server/7-http-web-server.ps1
http://community.idera.com/powershell/powertips/b/tips/posts/creating-powershell-web-server
https://gallery.technet.microsoft.com/scriptcenter/Powershell-Webserver-74dcf466

.NOTES
This script was created for completing the requirements of the SecurityTube PowerShell for Penetration Testers Certification Exam:
http://www.securitytube-training.com/online-courses/powershell-for-pentesters/
Student ID: PSP-6248
     
#>

[CmdletBinding()] 

       Param( 
       
       # Sets the webroot 
       [Parameter(Mandatory = $false)]
       [String]
       $WebRoot = ".",
       
       # Sets the hostname
       [Parameter(Mandatory = $false)]
       [String]
       $hostname = "localhost",
       
       #Sets the port
       [Parameter(Mandatory = $false)]
       [Int]
       $port = 8080
              
       )

#Create URL
$url = 'http://' + $hostname + ':' + $port + '/'


# HTML content for some URLs entered by the user
$htmlcontents = @{
  # Simple HTML returned for the base     
      "/"  =  { return '<html><building> Yet another PowerShell webserver </building></html>' }
      
      # Testing the response from function call's, in this case services running on host
      "/services"  =  { return Get-Service | ConvertTo-Html }
      # Listing of the files in the WebRoot
      "/list" = { return ls $WebRoot | ConvertTo-Html }
      
}

# start web server
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($url)
$listener.Start()

try
{
  while ($listener.IsListening) {  
    # process received request
    $context = $listener.GetContext()
    $Request = $context.Request
    $Response = $context.Response
    $querystring = $context.Request.QueryString[0]

    "$(Get-Date -Format T) $($Request.RemoteEndPoint.Address.ToString()) $($Request.httpMethod) $($Request.Url.PathAndQuery)"
    
    
    # is there HTML content for this URL?
    $Received = '{0} {1}' -f $Request.httpMethod, $Request.Url.LocalPath
    #$HTMLResponse = $HTMLResponseContents[$Received]
	$Result = ''


    
    if ($Received -eq 'GET /exit')
		{ # then break out of while loop
			"$(Get-Date -Format T) Stopping powershell webserver..."
			break;
		}
    
    
    else {
    
    switch ($Received)
		{
			"GET /list" {
             $Result = Get-ChildItem | select FullName | ConvertTo-Html
             break
            }

            "GET /exit" {
             $Result = $listener.stop()
             break
            }

            # To download a file place the filename (using the full path) in the querystring: /download?c:\users\username\file.txt
            "GET /download" {
            $Result = Get-Content $querystring
            break
            }


            # To upload - or rather create a new file on the server place the filename in the first querystring and contents in the next. Ex: /uploac?file=test.txt&content=contentstofile
            "GET /upload" { 
            $result = Set-Content -Path (Join-Path $WebRoot ($context.Request.QueryString[0])) -Value ($context.Request.QueryString[1]) 
            break
            }

            
            # To delete a file 
            "GET /delete" { 
            $result = Remove-Item -Path $querystring
            break
            }

                    
        }
	}
			
    $html = $Result
    if($html -ne $null){
    $buffer = [Text.Encoding]::UTF8.GetBytes($html) 
    $Response.ContentLength64 = $buffer.length
    $Response.OutputStream.Write($buffer, 0, $buffer.length)
    
    $Response.Close()
    }


}    
  
}
finally
{
  $listener.Stop()
}
}
