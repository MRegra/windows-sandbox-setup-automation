# --- SETUP VARIABLES ---
$intellijUrl = "https://download-cdn.jetbrains.com/idea/ideaIU-2025.1.3.exe"
$gitUrl      = "https://github.com/git-for-windows/git/releases/download/v2.50.1.windows.1/Git-2.50.1-64-bit.exe"
$javaUrl     = "https://download.oracle.com/java/21/archive/jdk-21.0.6_windows-x64_bin.exe"
$mavenUrl    = "https://dlcdn.apache.org/maven/maven-3/3.9.10/binaries/apache-maven-3.9.10-bin.zip"
$dockerUrl   = "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe"
$postgresUrl = "https://get.enterprisedb.com/postgresql/postgresql-17.5-3-windows-x64.exe"
$nvmUrl      = "https://github.com/coreybutler/nvm-windows/releases/latest/download/nvm-setup.exe"
$repoUrl     = "" # <--- SET YOUR GIT REPO HERE

# --- REQUIRE ADMIN ---
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Please run this script as Administrator."
    exit
}

# --- PROGRESS UTILS ---
$steps = @(
    "Setting up WSL (Linux Subsystem)", "Downloading tools", "Installing tools", "Configuring Maven & Java", 
    "Installing Node", "Cloning Repo", "Validating Setup", "Finalizing"
)
$totalSteps = $steps.Count
$stepCounter = 0
function Show-Progress($msg) {
    $percent = [math]::Round(($stepCounter / $totalSteps) * 100)
    Write-Progress -Activity "Developer Environment Setup" -Status "$msg ($stepCounter/$totalSteps)" -PercentComplete $percent
    Write-Host ">>> $msg"
}

# --- STEP 1: SETUP WSL ---
function Test-IfWindowsSandbox {
    $username = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    return $username -eq "WDAGUtilityAccount"
}

$stepCounter++
if (Test-IfWindowsSandbox) {
    Show-Progress "Skipping WSL setup (Windows Sandbox detected)"
    Write-Host "!! Detected Windows Sandbox environment. Skipping WSL setup... !!"
} else {
    # --- STEP 1: SETUP WSL ---
    Show-Progress "Setting up WSL (Linux Subsystem)"
    Write-Host "Enabling WSL and VirtualMachinePlatform features..."
    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
    wsl --set-default-version 2
    wsl --install -d Ubuntu
    wsl --set-default Ubuntu
    Start-Sleep -Seconds 10
    wsl -d Ubuntu -- bash -c "sudo apt update && sudo apt upgrade -y"
}

# --- STEP 2: DOWNLOAD TOOLS ---
$stepCounter++; Show-Progress "Downloading all required tools..."
function Get-File ($url, $name) {
    $dest = "$env:TEMP\$name"
    $percent = [math]::Round(($stepCounter / $totalSteps) * 100)
    $msg = "Downloading $name ..."
    Write-Progress -Activity "Tool Downloads" -Status $msg -PercentComplete $percent
    Invoke-WebRequest -Uri $url -OutFile $dest
    return $dest
}

$intellijPath = Get-File $intellijUrl "intellij.exe"
$gitPath      = Get-File $gitUrl "git.exe"
$javaPath     = Get-File $javaUrl "java.exe"
$dockerPath   = Get-File $dockerUrl "docker.exe"
$postgresPath = Get-File $postgresUrl "postgres.exe"
$nvmPath      = Get-File $nvmUrl "nvm.exe"
$mavenPath    = Get-File $mavenUrl "maven.zip"

# --- STEP 3: INSTALL TOOLS ---
$stepCounter++
Show-Progress "Installing tools silently..."
Start-Process $gitPath -ArgumentList "/VERYSILENT /NORESTART" -Wait
Start-Process $nvmPath -ArgumentList "/VERYSILENT /NORESTART" -Wait
Start-Process $intellijPath -ArgumentList "/S" -Wait
Start-Process $javaPath -ArgumentList "/s INSTALL_SILENT=Enable" -Wait
Start-Process $dockerPath -ArgumentList "install --quiet" -Wait
Start-Process $postgresPath -ArgumentList "--mode unattended --unattendedmodeui minimal" -Wait

# --- STEP 4: UNZIP MAVEN & ENV VARS ---
$stepCounter++
Show-Progress "Configuring Maven and Java paths..."
Expand-Archive -Path $mavenPath -DestinationPath "C:\tools\maven" -Force
$envVars = @{
    "MAVEN_HOME" = "C:\tools\maven\apache-maven-3.9.10"
    "JAVA_HOME"  = "C:\Program Files\Java\jdk-21"
    "Path"       = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";C:\tools\maven\apache-maven-3.9.10\bin;C:\Program Files\Java\jdk-21\bin"
}
foreach ($key in $envVars.Keys) {
    [System.Environment]::SetEnvironmentVariable($key, $envVars[$key], "Machine")
}

# --- STEP 5: INSTALL NODE ---
$stepCounter++
Show-Progress "Installing Node with NVM..."
Start-Sleep -Seconds 5
& "$env:ProgramFiles\nvm\nvm.exe" install latest
& "$env:ProgramFiles\nvm\nvm.exe" use latest

# --- STEP 6: CLONE REPO ---
$stepCounter++
Show-Progress "Cloning repository..."
if ($repoUrl -ne "") {
    git clone $repoUrl "$env:USERPROFILE\dev-project"
}

# --- STEP 7: VALIDATION ---
$stepCounter++; Show-Progress "Running validation checks..."
$validationResults = @()

function Test-Tool {
    param (
        [string]$Name, [string]$Command, [string]$Success, [string]$Failure
    )
    Write-Host "Checking $Name..."
    try {
        $output = & $Command 2>&1
        if ($LASTEXITCODE -eq 0 -or $output) {
            Write-Host "$Success"
            $validationResults += "$Name OK"
        } else {
            throw "No output"
        }
    } catch {
        Write-Host "$Failure"
        $validationResults += "$Name failed"
    }
}

Test-Tool "Git" "git --version" "Git is working." "Git not found."
Test-Tool "Java" "java -version" "Java is working." "Java not found."
Test-Tool "Javac" "javac -version" "JDK is working." "JDK not found."
Test-Tool "Maven" "mvn -v" "Maven is working." "Maven not found."
Test-Tool "Node.js" "node -v" "Node.js is working." "Node.js not found."
Test-Tool "NPM" "npm -v" "NPM is working." "NPM not found."
Test-Tool "Docker" "docker version --format '{{.Server.Version}}'" "Docker is working." "Docker not running or not found."
Test-Tool "PostgreSQL" "Get-Service -Name postgresql*" "PostgreSQL service installed." "PostgreSQL service not found."

# --- STEP 8: FINALIZATION ---
$stepCounter++
Show-Progress "Saving logs and preparing restart..."

$logPath = "$env:USERPROFILE\Desktop\validation-log.txt"
$validationResults | Out-File -FilePath $logPath -Encoding utf8
Write-Host "Validation results saved to: $logPath"
Write-Host "Setup complete. Restart is optional but recommended."
Write-Host "Restarting in 60 seconds. Press Ctrl+C to cancel."
Start-Sleep -Seconds 60
shutdown /r /t 0
