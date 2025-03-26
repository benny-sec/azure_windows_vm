# Function to check if a command exists
function Test-CommandExists {
    param ($command)
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = 'stop'
    try { if (Get-Command $command) { return $true } }
    catch { return $false }
    finally { $ErrorActionPreference = $oldPreference }
}

# Function to install .NET Framework 4.8
function Install-DotNetFramework {
    Write-Host "Installing .NET Framework 4.8..."
    $dotnetUrl = "https://go.microsoft.com/fwlink/?LinkId=2085155"
    $installerPath = "$env:TEMP\NDP48-x64.exe"
    
    (New-Object System.Net.WebClient).DownloadFile($dotnetUrl, $installerPath)
    Start-Process -FilePath $installerPath -ArgumentList "/q /norestart" -Wait
    
    # Clean up
    Remove-Item $installerPath
}

# Function to install Chocolatey if not present
function Install-Chocolatey {
    if (-not (Test-CommandExists choco)) {
        Write-Host "Installing Chocolatey..."
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    } else {
        Write-Host "Chocolatey is already installed"
    }
}

# Function to install a package using Chocolatey
function Install-Package {
    param (
        [string]$PackageName,
        [string]$Parameters = ""
    )
    Write-Host "Installing $PackageName..."
    if ($Parameters) {
        choco install $PackageName -y --params $Parameters
    } else {
        choco install $PackageName -y
    }
}

# Main installation script
try {
    # Disable UAC
    Write-Host "Disabling UAC..."
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value 0

    # Install .NET Framework 4.8 first
    Install-DotNetFramework

    # Install Chocolatey
    Install-Chocolatey

    # Install Git
    Install-Package "git"

    # Install Java
    Install-Package "temurin17"

    # Install PostgreSQL
    Install-Package "postgresql15" "/Password:$postgresPassword"

    # Install Google Chrome
    Install-Package "googlechrome"

    # Install Tabby
    Install-Package "tabby"

    # Set JAVA_HOME environment variable
    Write-Host "Setting JAVA_HOME environment variable..."
    $javaHome = "C:\Program Files\Java\jdk-17"
    [Environment]::SetEnvironmentVariable("JAVA_HOME", $javaHome, "Machine")
    [Environment]::SetEnvironmentVariable("Path", $env:Path + ";$javaHome\bin", "Machine")

    # Verify installations
    Write-Host "`nVerifying installations..."
    Write-Host "Git version:"
    git --version
    Write-Host "`nJava version:"
    & "$javaHome\bin\java" -version
    Write-Host "`nPostgreSQL version:"
    & "C:\Program Files\PostgreSQL\15\bin\psql" -V
    Write-Host "`nChrome version:"
    & "C:\Program Files\Google\Chrome\Application\chrome.exe" --version

    Write-Host "`nInstallation completed successfully!"
}
catch {
    Write-Error "An error occurred during installation: $_"
    throw
} 