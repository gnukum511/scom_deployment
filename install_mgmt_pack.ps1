# install_mgmt_pack.ps1

param (
    [string]$ManagementPackPath = "C:\SCOM\ManagementPacks"
)

# Ensure the Operations Manager PowerShell module is loaded
Import-Module OperationsManager

# Set the SCOM server connection
$SCOMServer = "scom-server"
New-SCOMManagementGroupConnection -ComputerName $SCOMServer

# Install all management packs from the specified path
Write-Host "Deploying Management Packs from $ManagementPackPath"
Get-ChildItem -Path $ManagementPackPath -Filter *.mp | ForEach-Object {
    Import-SCOMManagementPack -Path $_.FullName
}

Write-Host "Management Packs deployed successfully."
