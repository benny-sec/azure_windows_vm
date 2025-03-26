# Download Git installer
$gitUrl = "https://github.com/git-for-windows/git/releases/download/v2.44.0.windows.1/Git-2.44.0-64-bit.exe"
$installerPath = "$env:TEMP\GitInstaller.exe"
(New-Object System.Net.WebClient).DownloadFile($gitUrl, $installerPath)

# Install Git silently
Write-Host "Installing Git..."
Start-Process -FilePath $installerPath -ArgumentList "/VERYSILENT /NORESTART /NOCANCEL /SP- /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS /COMPONENTS='icons,ext\reg\shellhere,assoc,assoc_sh'" -Wait

# Clean up
Remove-Item $installerPath

# Wait for Git to be available in PATH
Write-Host "Waiting for Git to be available..."
$maxAttempts = 10
$attempt = 0
$gitAvailable = $false

while (-not $gitAvailable -and $attempt -lt $maxAttempts) {
    $attempt++
    Write-Host "Attempt $attempt of $maxAttempts..."
    try {
        $gitVersion = git --version
        if ($gitVersion) {
            $gitAvailable = $true
            Write-Host "Git is available: $gitVersion"
        }
    } catch {
        Write-Host "Git not available yet, waiting..."
        Start-Sleep -Seconds 5
    }
}

if (-not $gitAvailable) {
    throw "Git installation verification failed after $maxAttempts attempts"
}

# Create workspace directory if it doesn't exist
$workspacePath = "C:\workspace"
if (-not (Test-Path $workspacePath)) {
    Write-Host "Creating workspace directory..."
    New-Item -ItemType Directory -Path $workspacePath -Force
}

# Clone the repository
Write-Host "Cloning repository to $workspacePath..."
git clone https://github.com/benny-sec/azure_windows_vm.git "$workspacePath\azure_windows_vm"

# Verify the clone
if (Test-Path "$workspacePath\azure_windows_vm") {
    Write-Host "Repository cloned successfully!"
} else {
    throw "Repository clone failed"
}

Write-Host "Git installation and repository cloning completed!" 