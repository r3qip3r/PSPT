# Recursive function to retrieve all WMI namespaces on a system
# Credit: https://www.powershellmagazine.com/2013/10/18/pstip-list-all-wmi-namespaces-on-a-system/


Function Get-WmiNamespace {
    Param (
        $Namespace='root'
    )
    Get-WmiObject -Namespace $Namespace -Class __NAMESPACE | ForEach-Object {
            ($ns = '{0}\{1}' -f $_.__NAMESPACE,$_.Name)
            Get-WmiNamespace $ns
    }
}
