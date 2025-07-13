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
Invoke-WebRequest -Uri $intellijUrl -OutFile "$env:TEMP\intellij.exe"
Invoke-WebRequest -Uri $gitUrl -OutFile "$env:TEMP\git.exe"
Invoke-WebRequest -Uri $javaUrl -OutFile "$env:TEMP\java.exe"
Invoke-WebRequest -Uri $dockerUrl -OutFile "$env:TEMP\docker.exe"
Invoke-WebRequest -Uri $postgresUrl -OutFile "$env:TEMP\postgres.exe"
Invoke-WebRequest -Uri $nvmUrl -OutFile "$env:TEMP\nvm.exe"
Invoke-WebRequest -Uri $mavenUrl -OutFile "$env:TEMP\maven.zip"

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

Write-Host "✅ Setup complete. You may need to restart the Sandbox for env vars to apply."
