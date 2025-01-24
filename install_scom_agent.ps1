# install_scom_agent.ps1

param (
    [string]$SCOMServer = "scom-server",
    [string]$AgentInstallPath = "C:\SCOM\Agent"
)

Write-Host "Downloading and installing SCOM Agent..."

# Download the SCOM agent installation package
$AgentUrl = "https://path-to-agent.msi"
$AgentInstaller = "$AgentInstallPath\SCOM_Agent.msi"
Invoke-WebRequest -Uri $AgentUrl -OutFile $AgentInstaller

# Install the SCOM Agent
Start-Process msiexec.exe -ArgumentList "/i $AgentInstaller /qn MANAGEMENT_GROUP=$SCOMServer" -Wait

Write-Host "SCOM Agent installation complete."
