function Convert-IPAddress {
  <#
  .SYNOPSIS
    Converts an IPv4 address to IPv6
  .EXAMPLE
    Convert-IPAddress -IPv4 192.168.10.10
  #>
    param (
        [Parameter(Mandatory = $true)]
        [System.Net.IPAddress]$IPv4
    )

    $Octets = $IPv4.IPAddressToString.Split('.')
    $Hex = $Octets | ForEach-Object { '{0:x2}' -f [int]$_ }
    $IPv6 = "::ffff:$($Hex[0..1] -join ''):$($Hex[2..3] -join '')"

    return $IPv6
}
