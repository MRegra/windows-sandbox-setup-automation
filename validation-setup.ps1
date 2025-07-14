Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

# --- STEP 6: VALIDATION ---
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
Test-Tool "Docker" "docker version" "Docker is working." "Docker not running or not found."
Test-Tool "PostgreSQL" "Get-Service -Name postgresql*" "PostgreSQL service installed." "PostgreSQL service not found."
Test-Tool "Angular CLI" "ng version" "Angular CLI is working." "Angular CLI not found."
Test-Tool "Postman" "Get-ChildItem -Recurse -Path $env:LOCALAPPDATA -Filter 'Postman.exe' -ErrorAction SilentlyContinue | Select-Object -First 1" "Postman installed." "Postman not found."
Test-Tool "VS Code" "code --version" "VS Code is working." "VS Code not found."
Test-Tool "npm-check" "npm-check --version" "npm-check is working." "npm-check not found."

Show-Progress "Saving logs"
$logPath = "$env:USERPROFILE\Desktop\validation-log.txt"
$validationResults | Out-File -FilePath $logPath -Encoding utf8
Write-Progress "Validation results saved to: $logPath"
