# --- SETUP VARIABLES ---
## -- URL VARIABLES --
$intellijUrl = "https://download-cdn.jetbrains.com/idea/ideaIU-2025.1.3.exe"
$gitUrl      = "https://github.com/git-for-windows/git/releases/download/v2.50.1.windows.1/Git-2.50.1-64-bit.exe"
$javaUrl     = "https://download.oracle.com/java/21/archive/jdk-21.0.6_windows-x64_bin.exe"
$mavenUrl    = "https://dlcdn.apache.org/maven/maven-3/3.9.10/binaries/apache-maven-3.9.10-bin.zip"
$dockerUrl   = "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe"
$postgresUrl = "https://get.enterprisedb.com/postgresql/postgresql-17.5-3-windows-x64.exe"
$nvmUrl      = "https://github.com/coreybutler/nvm-windows/releases/latest/download/nvm-setup.exe"
$vscodeUrl  = "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64-user"
$postmanUrl = "https://dl.pstmn.io/download/latest/win64"
$repoUrl     = "" # <--- SET YOUR GIT REPO HERE

## -- PATH VARIABLES --
$mavenExtractPath = "C:\tools\maven"
$mavenVersion = "apache-maven-3.9.10"
$mavenFullPath = "$mavenExtractPath\$mavenVersion"
$javaPathVar = "C:\Program Files\Java\jdk-21"

# --- REQUIRE ADMIN ---
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Please run this script as Administrator."
    exit
}

$ProgressPreference = 'Continue'

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
    $script:stepCounter++
}

function Test-IfWindowsSandbox {
    $username = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    return $username -match "WDAGUtilityAccount" -or $env:USERNAME -eq 'WDAGUtilityAccount'
}

if (Test-IfWindowsSandbox) {
    Show-Progress "Skipping WSL setup (Windows Sandbox detected)"
} else {
    # --- STEP 1: SETUP WSL ---
    Show-Progress "Setting up WSL (Linux Subsystem)"
    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
    wsl --set-default-version 2
    wsl --install -d Ubuntu
    wsl --set-default Ubuntu
    Start-Sleep -Seconds 10
    wsl -d Ubuntu -- bash -c "sudo apt update && sudo apt upgrade -y"
}

# --- STEP 2: DOWNLOAD TOOLS ---
Show-Progress "Downloading all required tools..."
function Start-ParallelDownload {
    param (
        [string]$url, [string]$name
    )
    $dest = "$env:TEMP\$name"
    Write-Host "Downloading $name..." -ForegroundColor Yellow
    Start-Job -ScriptBlock {
        param($url, $dest)
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing
    } -ArgumentList $url, $dest | Out-Null
    return $dest
}

# Start downloads in parallel
$intellijPath = Start-ParallelDownload $intellijUrl "intellij.exe"
$gitPath      = Start-ParallelDownload $gitUrl "git.exe"
$javaPath     = Start-ParallelDownload $javaUrl "java.exe"
$dockerPath   = Start-ParallelDownload $dockerUrl "docker.exe"
$postgresPath = Start-ParallelDownload $postgresUrl "postgres.exe"
$nvmPath      = Start-ParallelDownload $nvmUrl "nvm.exe"
$mavenPath    = Start-ParallelDownload $mavenUrl "maven.zip"
$vscodePath   = Start-ParallelDownload $vscodeUrl "vscode.exe"
$postmanPath  = Start-ParallelDownload $postmanUrl "postman.exe"

# Wait for all jobs to finish
Show-Progress "Waiting for downloads to complete..."
while (Get-Job | Where-Object { $_.State -eq 'Running' }) {
    Start-Sleep -Seconds 2
}
$jobs = Get-Job

foreach ($job in $jobs) {
    $jobName = $job.Command
    $result = Receive-Job -Job $job -ErrorAction SilentlyContinue
    
    if ($job.State -eq 'Completed') {
        Write-Host "Job $jobName completed." -ForegroundColor Green
        if ($result) {
            Write-Host "Output:" -ForegroundColor DarkGray
            Write-Output $result
        }
    } else {
        Write-Host "[X] Job $jobName failed or incomplete." -ForegroundColor Red
        if ($result) {
            Write-Host "Error Output:" -ForegroundColor Red
            Write-Output $result
        }
    }

    Remove-Job -Job $job
}

# --- STEP 3: INSTALL TOOLS ---
Show-Progress "Installing tools silently..."
Start-Process $gitPath -ArgumentList "/VERYSILENT /NORESTART" -Wait
Start-Process $nvmPath -ArgumentList "/VERYSILENT /NORESTART" -Wait
Start-Process $intellijPath -ArgumentList "/S" -Wait
Start-Process $javaPath -ArgumentList "/s INSTALL_SILENT=Enable" -Wait
Start-Process $dockerPath -ArgumentList "install --quiet" -Wait
Start-Process $postgresPath -ArgumentList "--mode unattended --unattendedmodeui minimal" -Wait
Start-Process $vscodePath -ArgumentList "/silent /mergetasks=!runcode" -Wait
Start-Process $postmanPath -ArgumentList "/silent" -Wait

# --- STEP 4: UNZIP MAVEN & ENV VARS ---
Show-Progress "Configuring Maven and Java paths..."
Expand-Archive -Path $mavenPath -DestinationPath $mavenExtractPath -Force

$envVars = @{
    "MAVEN_HOME" = $mavenFullPath
    "JAVA_HOME"  = $javaPathVar
    "Path"       = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";$mavenFullPath\bin;$javaPathVar\bin"
}

foreach ($key in $envVars.Keys) {
    [System.Environment]::SetEnvironmentVariable($key, $envVars[$key], "Machine")
}

# --- STEP 5: INSTALL NODE ---
Show-Progress "Installing Node with NVM..."
Start-Sleep -Seconds 5
# Try common install paths
$nvmPossiblePaths = @(
    "$env:ProgramFiles\nvm\nvm.exe",
    "$env:ProgramFiles(x86)\nvm\nvm.exe",
    "$env:LOCALAPPDATA\nvm\nvm.exe"
)

$nvmExe = $nvmPossiblePaths | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $nvmExe) {
    Write-Error "NVM executable not found. Installation may have failed."
    exit 1
}

# Add NVM and Node paths manually to current session
$nvmDir = Split-Path $nvmExe
$env:PATH += ";$nvmDir"

# Install and use latest Node.js
& $nvmExe install latest
& $nvmExe use latest

# Now install Angular CLI and Dev Tools
npm install -g @angular/cli
npm install -g npm-check

$vsCodePath = "$env:LOCALAPPDATA\Programs\Microsoft VS Code\bin"
if (Test-Path $vsCodePath) {
    $env:PATH += ";$vsCodePath"
}

code --install-extension Angular.ng-template
code --install-extension johnpapa.angular2

# --- STEP 6: CLONE REPO ---
Show-Progress "Cloning repository..."
if ($repoUrl -ne "") {
    git clone $repoUrl "$env:USERPROFILE\dev-project"
}

# --- STEP 7: VALIDATION ---
Show-Progress "Running validation checks..."
$validationResults = @()

function Test-Tool {
    param (
        [string]$Name, [string]$Command, [string]$Success, [string]$Failure
    )
    Write-Progress "Checking $Name..."
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
Test-Tool "Angular CLI" "ng version" "Angular CLI is working." "Angular CLI not found."
Test-Tool "Postman" "Get-ChildItem -Recurse -Path $env:LOCALAPPDATA -Filter 'Postman.exe' -ErrorAction SilentlyContinue | Select-Object -First 1" "Postman installed." "Postman not found."
Test-Tool "VS Code" "code --version" "VS Code is working." "VS Code not found."
Test-Tool "npm-check" "npm-check --version" "npm-check is working." "npm-check not found."

# --- STEP 8: FINALIZATION ---
Show-Progress "Saving logs and preparing restart..."

$logPath = "$env:USERPROFILE\Desktop\validation-log.txt"
$validationResults | Out-File -FilePath $logPath -Encoding utf8
Write-Progress "Validation results saved to: $logPath"
Write-Progress "Setup complete. Restart is optional but recommended."
Write-Progress "Restarting in 60 seconds. Press Ctrl+C to cancel."
Start-Sleep -Seconds 60
shutdown /r /t 0
