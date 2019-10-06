<#

.DESCRIPTION
A fast search for a string in a given registry subkey.

.SYNOPSIS
PowerShell script to quicly search for a string in Windows Registry.

.DESCRIPTION
The script searches for a text string in the Registry.

.PARAMETER Searchstring
A string to search for
 
.PARAMETER Rootkey
Sets the RootKey to be either HKCU(default) or HKLM
 
.PARAMETER Subkey
Sets the starting subkey. Default is "Software"

.EXAMPLE
Search-RegistryString -SearchString password -RootKey HKCU -Subkey software

.LINK
https://stackoverflow.com/a/55853204


.NOTES
This script was created for completing the requirements of the SecurityTube PowerShell for Penetration Testers Certification Exam:
http://www.securitytube-training.com/online-courses/powershell-for-pentesters/
Student ID: PSP-6248

#>

function Search-RegistryString {

param (

    # String to search for in registry
    [Parameter(Mandatory = $true)]
    [String]
    $SearchString,

    # Select the Registry hive - Defaults to HKCU
    [Parameter(Mandatory = $true)]
    [ValidateSet ("HKCU", "HKLM")]
    [String]
    $RootKey = "HKCU",

    # Select Registry subkey. Defaults to "software"
    [Parameter(Mandatory = $true)]
    [String]
    $Subkey = "software"

)



# The following code is copied from: https://stackoverflow.com/questions/39221709/speed-up-powershell-script-for-registry-search-currently-30min/55853204#55853204
# -----------------------------------------------------------------------------------
# carsten.giese@googlemail.com
# reference: https://msdn.microsoft.com/de-de/vstudio/ms724875(v=vs.80)

$ErrorActionPreference = "stop"

$signature = @'
[DllImport("advapi32.dll")]
public static extern Int32 RegOpenKeyEx(
    UInt32 hkey,
    StringBuilder lpSubKey,
    int ulOptions,
    int samDesired,
    out IntPtr phkResult
    );

[DllImport("advapi32.dll")]
public static extern Int32 RegQueryInfoKey(
    IntPtr hKey,
    StringBuilder lpClass, Int32 lpCls, Int32 spare, 
    out int subkeys, out int skLen, int mcLen, out int values,
    out int vNLen, out int mvLen, int secDesc,                
    out System.Runtime.InteropServices.ComTypes.FILETIME lpftLastWriteTime
);

[DllImport("advapi32.dll", CharSet = CharSet.Unicode)]
public static extern Int32 RegEnumValue(
  IntPtr hKey,
  int dwIndex,
  IntPtr lpValueName,
  ref IntPtr lpcchValueName,
  IntPtr lpReserved,
  out IntPtr lpType,
  IntPtr lpData,
  ref int lpcbData
);

[DllImport("advapi32.dll", CharSet = CharSet.Unicode)]
public static extern Int32 RegEnumKeyEx(
  IntPtr hKey,
  int dwIndex,
  IntPtr lpName,
  ref int lpcName,
  IntPtr lpReserved,
  IntPtr lpClass,
  int lpcClass,
  out System.Runtime.InteropServices.ComTypes.FILETIME lpftLastWriteTime
);

[DllImport("advapi32.dll")]
public static extern Int32 RegCloseKey(IntPtr hkey);
'@ 
$reg = add-type $signature -Name reg -Using System.Text -PassThru
$marshal = [System.Runtime.InteropServices.Marshal]

function search-RegistryTree($path) {

    # open the key:
    [IntPtr]$hkey = 0
    $result = $reg::RegOpenKeyEx($global:hive, $path, 0, 25,[ref]$hkey)
    if ($result -eq 0) {

        # get details of the key:
        $subKeyCount  = 0
        $maxSubKeyLen = 0
        $valueCount   = 0
        $maxNameLen   = 0
        $maxValueLen  = 0
        $time = $global:time
        $result = $reg::RegQueryInfoKey($hkey,$null,0,0,[ref]$subKeyCount,[ref]$maxSubKeyLen,0,[ref]$valueCount,[ref]$maxNameLen,[ref]$maxValueLen,0,[ref]$time)
        if ($result -eq 0) {
           $maxSubkeyLen += $maxSubkeyLen+1
           $maxNameLen   += $maxNameLen  +1
           $maxValueLen  += $maxValueLen +1
        }

        # enumerate the values:
        if ($valueCount -gt 0) {
            $type = [IntPtr]0
            $pName  = $marshal::AllocHGlobal($maxNameLen)
            $pValue = $marshal::AllocHGlobal($maxValueLen)
            foreach ($index in 0..($valueCount-1)) {
                $nameLen  = $maxNameLen
                $valueLen = $maxValueLen
                $result = $reg::RegEnumValue($hkey, $index, $pName, [ref]$nameLen, 0, [ref]$type, $pValue, [ref]$valueLen)
                if ($result -eq 0) {
                    $name = $marshal::PtrToStringUni($pName)
                    $value = switch ($type) {
                        1 {$marshal::PtrToStringUni($pValue)}
                        2 {$marshal::PtrToStringUni($pValue)}
                        3 {$b = [byte[]]::new($valueLen)
                           $marshal::Copy($pValue,$b,0,$valueLen)
                           if ($b[1] -eq 0 -and $b[-1] -eq 0 -and $b[0] -ne 0) {
                                [System.Text.Encoding]::Unicode.GetString($b)
                           } else {
                                [System.Text.Encoding]::UTF8.GetString($b)}
                           }
                        4 {$marshal::ReadInt32($pValue)}
                        7 {$b = [byte[]]::new($valueLen)
                           $marshal::Copy($pValue,$b,0,$valueLen)
                           $msz = [System.Text.Encoding]::Unicode.GetString($b)
                           $msz.TrimEnd(0).split(0)}
                       11 {$marshal::ReadInt64($pValue)}
                    }
                    if ($name -match $global:search) {
                        write-host "$path\$name : $value `n"
                        $global:hits++
                    } elseif ($value -match $global:search) {
                        write-host "$path\$name : $value `n"
                        $global:hits++
                    }
                }
            }
            $marshal::FreeHGlobal($pName)
            $marshal::FreeHGlobal($pValue)
        }

        # enumerate the subkeys:
        if ($subkeyCount -gt 0) {
            $subKeyList = @()
            $pName = $marshal::AllocHGlobal($maxSubkeyLen)
            $subkeyList = foreach ($index in 0..($subkeyCount-1)) {
                $nameLen = $maxSubkeyLen
                $result = $reg::RegEnumKeyEx($hkey, $index, $pName, [ref]$nameLen,0,0,0, [ref]$time)
                if ($result -eq 0) {
                    $marshal::PtrToStringUni($pName)
                }
            }
            $marshal::FreeHGlobal($pName)
        }

        # close:
        $result = $reg::RegCloseKey($hkey)

        # get Tree-Size from each subkey:
        $subKeyValueCount = 0
        if ($subkeyCount -gt 0) {
            foreach ($subkey in $subkeyList) {
                $subKeyValueCount += search-RegistryTree "$path\$subkey"
            }
        }
        return ($valueCount+$subKeyValueCount)
    }
}

$timer = [System.Diagnostics.Stopwatch]::new()
$timer.Start()

# -----------------------------------------------------------------------------------------



# setting global variables:
$global:search = $SearchString

$global:hive = Switch($RootKey) {
    "HKCU" {[uint32]"0x80000001"}
    "HKLM" {[uint32]"0x80000002"}
              } 
                                                          
$time   = New-Object System.Runtime.InteropServices.ComTypes.FILETIME
$global:hits   = 0

write-host "Searching for pattern '$search' in $RootKey\$subkey ...`n" -ForegroundColor Green
$count = search-RegistryTree $subkey

$timer.stop()
$sec = [int](100 * $timer.Elapsed.TotalSeconds)/100
write-host "`n$count reg-values has been checked in $sec seconds. Number of hits = $hits." -ForegroundColor Green
}
