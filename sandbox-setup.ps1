# --- SETUP VARIABLES (YOU CAN FILL THESE URLs WITH LATEST VERSIONS) ---
$intellijUrl     = "https://download-cdn.jetbrains.com/idea/ideaIU-2025.1.3.exe"
$gitUrl          = "https://github.com/git-for-windows/git/releases/download/v2.50.1.windows.1/Git-2.50.1-64-bit.exe"
$javaUrl         = "https://download.oracle.com/java/21/archive/jdk-21.0.6_windows-x64_bin.exe"
$mavenUrl        = "https://dlcdn.apache.org/maven/maven-3/3.9.10/binaries/apache-maven-3.9.10-bin.zip"
$dockerUrl       = "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe"
$postgresUrl     = "https://get.enterprisedb.com/postgresql/postgresql-17.5-3-windows-x64.exe"
$nvmUrl          = "https://github.com/coreybutler/nvm-windows/releases/latest/download/nvm-setup.exe"
$repoUrl         = "" # To be created

# --- DOWNLOAD INSTALLERS ---
Start-BitsTransfer -Source $intellijUrl -Destination "$env:TEMP\intellij.exe"
Start-BitsTransfer -Source $gitUrl -Destination "$env:TEMP\git.exe"
Start-BitsTransfer -Source $javaUrl -Destination "$env:TEMP\java.exe"
Start-BitsTransfer -Source $dockerUrl -Destination "$env:TEMP\docker.exe"
Start-BitsTransfer -Source $postgresUrl -Destination "$env:TEMP\postgres.exe"
Start-BitsTransfer -Source $nvmUrl -Destination "$env:TEMP\nvm.exe"
Start-BitsTransfer -Source $mavenUrl -Destination "$env:TEMP\maven.zip"

# --- INSTALL ---
Start-Process "$env:TEMP\git.exe" -Wait
Start-Process "$env:TEMP\nvm.exe" -Wait
Start-Process "$env:TEMP\intellij.exe" -Wait
Start-Process "$env:TEMP\java.exe" -Wait
Start-Process "$env:TEMP\docker.exe" -Wait
Start-Process "$env:TEMP\postgres.exe" -Wait

# --- UNZIP MAVEN & SET ENV VARIABLES ---
Expand-Archive -Path "$env:TEMP\maven.zip" -DestinationPath "C:\tools\maven" -Force
[System.Environment]::SetEnvironmentVariable("MAVEN_HOME", "C:\tools\maven\apache-maven-3.9.6", "Machine")
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

Write-Host "✅ Setup complete. You may need to restart the Sandbox for env vars to apply."
