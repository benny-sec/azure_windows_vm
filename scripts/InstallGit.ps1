# Download Git installer
$gitUrl = "https://github.com/git-for-windows/git/releases/download/v2.44.0.windows.1/Git-2.44.0-64-bit.exe"
$installerPath = "$env:TEMP\GitInstaller.exe"
(New-Object System.Net.WebClient).DownloadFile($gitUrl, $installerPath)

# Install Git silently
Start-Process -FilePath $installerPath -ArgumentList "/VERYSILENT /NORESTART /NOCANCEL /SP- /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS /COMPONENTS='icons,ext\reg\shellhere,assoc,assoc_sh'" -Wait

# Clean up
Remove-Item $installerPath

# Verify Git installation
git --version

# Create workspace directory if it doesn't exist
$workspacePath = "C:\workspace"
if (-not (Test-Path $workspacePath)) {
    New-Item -ItemType Directory -Path $workspacePath
}

# Clone the repository
Write-Host "Cloning repository to $workspacePath..."
git clone https://github.com/benny-sec/azure_windows_vm.git "$workspacePath\azure_windows_vm"

Write-Host "Git installation and repository cloning completed!" 