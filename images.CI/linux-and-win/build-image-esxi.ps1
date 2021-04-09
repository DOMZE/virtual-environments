param(
    [String] [Parameter (Mandatory=$true)] $TemplatePath,
    [String] [Parameter (Mandatory=$true)] $BuilderHost,
    [String] [Parameter (Mandatory=$true)] $BuilderHostUsername,
    [String] [Parameter (Mandatory=$true)] $BuilderHostPassword,
    [String] [Parameter (Mandatory=$true)] $BuilderHostDataStore,
    [String] [Parameter (Mandatory=$true)] $BuilderHostPortGroup,   
    [String] [Parameter (Mandatory=$true)] $VMName,
    [String] [Parameter (Mandatory=$true)] $ISOLocalPath,
    [String] [Parameter (Mandatory=$true)] $ISOChecksum,
    [String] [Parameter (Mandatory=$true)] $GitHubFeedToken,
    [String] [Parameter (Mandatory=$true)] $ImageVersion
)

if (-not (Test-Path $TemplatePath))
{
    Write-Error "'-TemplatePath' parameter is not valid. You have to specify correct Template Path"
    exit 1
}

$Image = [io.path]::GetFileNameWithoutExtension($TemplatePath)

# set the preseed with the correct password
$preseedData = Get-Content -Path "$TemplatePath/http/preseed.cfg" | ForEach-Object {
    if ($_ -match "passwd/user-password") {
        $line = $_
        $items = $line.Split(" ")
        $items[3] = $InstallPassword
        $newline = $items | Join-String -Separator " "
        $newline
    }
    else {
        $_
    }
}

$preseedData | Set-Content "$TemplatePath/http/preseed.cfg"

packer validate -syntax-only $TemplatePath

$SensitiveData = @(
    ':  ->'
)

Write-Host "Show Packer Version"
packer --version

Write-Host "Build $Image VM"
packer build    -var "builder_host=$BuilderHost" `
                -var "builder_host_username=$BuilderHostUsername" `
                -var "builder_host_password=$BuilderHostPassword" `
                -var "builder_host_datastore=$BuilderHostDataStore" `
                -var "builder_host_portgroup=$BuilderHostPortGroup" `
                -var "ovftool_deploy_vcenter=$VCenterHost" `
                -var "ovftool_deploy_vcenter_username=$VCenterHostUsername" `
                -var "ovftool_deploy_vcenter_password=$VCenterHostPassword" `
                -var "vm_name=$VMName-$ImageVersion" `
                -var "iso_local_path=$ISOLocalPath" `
                -var "iso_checksum=$ISOChecksum" `
                -var "run_validation_diskspace=$env:RUN_VALIDATION_FLAG" `
                -var "github_feed_token=$GitHubFeedToken" `
                -var "image_version=$ImageVersion"
                $TemplatePath `
        | Where-Object {
            #Filter sensitive data from Packer logs
            $currentString = $_
            $sensitiveString = $SensitiveData | Where-Object { $currentString -match $_ }
            $sensitiveString -eq $null
        }