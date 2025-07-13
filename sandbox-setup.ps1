# --- SETUP VARIABLES (YOU CAN FILL THESE URLs WITH LATEST VERSIONS) ---
$intellijUrl     = "https://download-cdn.jetbrains.com/idea/ideaIU-2025.1.3.exe"
$gitUrl          = "https://github.com/git-for-windows/git/releases/download/v2.50.1.windows.1/Git-2.50.1-64-bit.exe"
$javaUrl         = "https://download.oracle.com/java/21/archive/jdk-21.0.6_windows-x64_bin.exe"
$mavenUrl        = "https://dlcdn.apache.org/maven/maven-3/3.9.10/binaries/apache-maven-3.9.10-bin.zip"
$dockerUrl       = "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe"
$postgresUrl     = "https://get.enterprisedb.com/postgresql/postgresql-17.5-3-windows-x64.exe"
$nvmUrl          = "https://github.com/coreybutler/nvm-windows/releases/latest/download/nvm-setup.exe"
$repoUrl         = "" # To be created

# --- PROGRESS BAR AUXILIARS ---
$steps = @(
    "Downloading IntelliJ", "Downloading Git", "Downloading Java", "Downloading Docker", "Downloading PostgreSQL", "Downloading NVM", "Downloading Maven",
    "Installing Git", "Installing NVM", "Installing IntelliJ", "Installing Java", "Installing Docker", "Installing PostgreSQL",
    "Unzipping Maven & Setting Env Vars", "Installing Node with NVM",
    "Cloning Repo", "Validating Installations", "Saving Validation Log"
)

$totalSteps = $steps.Count
$stepCounter = 0

function Show-Progress($message) {
    $percent = [math]::Round(($stepCounter / $totalSteps) * 100)
    Write-Progress -Activity "Setting up your dev environment..." `
                   -Status "$message ($stepCounter of $totalSteps)" `
                   -PercentComplete $percent
}

# --- INSTALL WSL FIRST ---
$stepCounter++
Show-Progress "Setting up WSL (Windows Subsystem for Linux)"

# 1. Enable required features
Write-Host "Enabling WSL and VirtualMachinePlatform features..."
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

# 2. Download and install WSL (if needed)
Write-Host "Installing latest WSL version..."
wsl --install --no-distribution

# 3. Download and install a Linux distro (e.g., Ubuntu)
Write-Host "Installing Ubuntu from Microsoft Store..."
wsl --install -d Ubuntu

# Optional: Set Ubuntu as default
wsl --set-default Ubuntu

# 4. (Optional) Run post-install commands inside WSL
Write-Host "Waiting for WSL to finish initializing..."
Start-Sleep -Seconds 10

# Sample post-install setup (e.g., updating Ubuntu packages)
Write-Host "Running post-install update in WSL..."
wsl -d Ubuntu -- bash -c "sudo apt update && sudo apt upgrade -y"

# --- DOWNLOAD INSTALLERS ---
$stepCounter++
Show-Progress "Downloading IntelliJ"
Start-BitsTransfer -Source $intellijUrl -Destination "$env:TEMP\intellij.exe"
$stepCounter++
Show-Progress "Downloading Git"
Start-BitsTransfer -Source $gitUrl -Destination "$env:TEMP\git.exe"
$stepCounter++
Show-Progress "Downloading Java"
Start-BitsTransfer -Source $javaUrl -Destination "$env:TEMP\java.exe"
$stepCounter++
Show-Progress "Downloading Docker"
Start-BitsTransfer -Source $dockerUrl -Destination "$env:TEMP\docker.exe"
$stepCounter++
Show-Progress "Downloading PostgreSQL"
Start-BitsTransfer -Source $postgresUrl -Destination "$env:TEMP\postgres.exe"
$stepCounter++
Show-Progress "Downloading NVM"
Start-BitsTransfer -Source $nvmUrl -Destination "$env:TEMP\nvm.exe"
$stepCounter++
Show-Progress "Downloading Maven"
Start-BitsTransfer -Source $mavenUrl -Destination "$env:TEMP\maven.zip"

# --- INSTALL ---
# Start-Process "$env:TEMP\git.exe" -Wait
# Start-Process "$env:TEMP\nvm.exe" -Wait
# Start-Process "$env:TEMP\intellij.exe" -Wait
# Start-Process "$env:TEMP\java.exe" -Wait
# Start-Process "$env:TEMP\docker.exe" -Wait
# Start-Process "$env:TEMP\postgres.exe" -Wait

# --- INSTALL SILENTLY ---
$stepCounter++
Show-Progress "Installing Git"
Start-Process "$env:TEMP\git.exe" -ArgumentList "/VERYSILENT /NORESTART" -Wait
Write-Host "Installing NVM..."
Start-Process "$env:TEMP\nvm.exe" -ArgumentList "/VERYSILENT /NORESTART" -Wait
Write-Host "Installing IntelliJ IDEA..."
Start-Process "$env:TEMP\intellij.exe" -ArgumentList "/S" -Wait
Write-Host "Installing Java 21 (JDK)..."
Start-Process "$env:TEMP\java.exe" -ArgumentList "/s INSTALL_SILENT=Enable" -Wait
Write-Host "Installing Docker..."
Start-Process "$env:TEMP\docker.exe" -ArgumentList "install --quiet" -Wait
Write-Host "Installing PostgreSQL..."
Start-Process "$env:TEMP\postgres.exe" -ArgumentList "--mode unattended --unattendedmodeui minimal" -Wait

# --- UNZIP MAVEN & SET ENV VARIABLES ---
Expand-Archive -Path "$env:TEMP\maven.zip" -DestinationPath "C:\tools\maven" -Force
[System.Environment]::SetEnvironmentVariable("MAVEN_HOME", "C:\tools\maven\apache-maven-3.9.10", "Machine")
[System.Environment]::SetEnvironmentVariable("JAVA_HOME", "C:\Program Files\Java\jdk-21", "Machine")
[System.Environment]::SetEnvironmentVariable("Path", $env:Path + ";$env:MAVEN_HOME\bin;$env:JAVA_HOME\bin", "Machine")

# --- INSTALL NODE (after NVM is installed) ---
Start-Sleep -Seconds 5
& "$env:ProgramFiles\nvm\nvm.exe" install latest
& "$env:ProgramFiles\nvm\nvm.exe" use latest

# --- CLONE REPO ---
git clone $repoUrl "$env:USERPROFILE\dev-project"

# --- VALIDATION SECTION ---
$validationResults = @()

function Test-Tool {
    param (
        [string]$Name,
        [string]$Command,
        [string]$SuccessMessage,
        [string]$FailMessage
    )

    Write-Host "Checking $Name..."
    try {
        $output = & $Command 2>&1
        if ($LASTEXITCODE -eq 0 -or $output) {
            Write-Host "✅ $SuccessMessage"
            $validationResults += "✅ $Name installed successfully"
        } else {
            throw "No output"
        }
    } catch {
        Write-Host "❌ $FailMessage"
        $validationResults += "❌ $Name installation failed"
    }
}

# Run checks
Test-Tool -Name "Git" -Command "git --version" `
    -SuccessMessage "Git is working!" `
    -FailMessage "Git not found."

Test-Tool -Name "Java" -Command "java -version" `
    -SuccessMessage "Java is working!" `
    -FailMessage "Java not found."

Test-Tool -Name "Javac (JDK)" -Command "javac -version" `
    -SuccessMessage "JDK (javac) is working!" `
    -FailMessage "JDK (javac) not found."

Test-Tool -Name "Maven" -Command "mvn -v" `
    -SuccessMessage "Maven is working!" `
    -FailMessage "Maven not found."

Test-Tool -Name "Node.js" -Command "node -v" `
    -SuccessMessage "Node.js is working!" `
    -FailMessage "Node.js not found."

Test-Tool -Name "NPM" -Command "npm -v" `
    -SuccessMessage "NPM is working!" `
    -FailMessage "NPM not found."

Test-Tool -Name "Docker" -Command "docker version --format '{{.Server.Version}}'" `
    -SuccessMessage "Docker is working!" `
    -FailMessage "Docker not found or not running."

Test-Tool -Name "PostgreSQL Service" -Command "Get-Service -Name postgresql*" `
    -SuccessMessage "PostgreSQL service is installed!" `
    -FailMessage "PostgreSQL service not found."

# --- SAVE LOG ---
$logPath = "$env:USERPROFILE\Desktop\validation-log.txt"
$validationResults | Out-File -FilePath $logPath -Encoding utf8

Write-Host "Validation results saved to: $logPath"

Write-Host "✅ Setup complete. Press Ctrl+C in the next 60 seconds to cancel the automatic restart."
Start-Sleep -Seconds 60
shutdown /r /t 0
