[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True)]
    [string] $VCenterServerHostName,
    [Parameter(Mandatory=$True)]
    [string] $VCenterUserName,
    [Parameter(Mandatory=$True)]
    [string] $VCenterPassword,
    [Parameter(Mandatory=$True)]
    [string] $VMName
)

$ErrorActionPreference = 'stop'
try {
    Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false
    Connect-VIServer -Server "$VCenterServerHostName" -User "$VCenterUserName" -Password "$VCenterPassword"
    $vm = Get-VM "$VMName"
    $vm.ExtensionData.UnregisterVM()
    Disconnect-VIServer * -Confirm:$false
}
catch {
    $ErrorMessage = $_.Exception.Message
    Write-Error "An error occurred while unregistering the virtual machine $($VMName): $ErrorMessage"
}
