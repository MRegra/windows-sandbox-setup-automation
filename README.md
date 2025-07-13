# Windows Sandbox Dev Environment Setup

This project automates the creation of a clean, ready-to-code DevOps environment using **Windows Sandbox** and **WSL2**. Every time you open the sandbox, it installs all necessary tools from scratch, giving you a fresh, disposable, production-like setup in minutes.

---

## What It Installs

**Windows Environment (via `sandbox-setup.ps1`):**
- [ ] IntelliJ IDEA Community Edition
- [ ] Git & Git Bash
- [ ] Java JDK 21
- [ ] Maven
- [ ] Docker Desktop
- [ ] PostgreSQL
- [ ] NVM + Node.js + npm
- [ ] Clones the latest version of your GitLab repo

**WSL2 Linux Environment (via `wsl-setup.sh`):**
- [ ] Java 21 (OpenJDK)
- [ ] Maven
- [ ] Docker (Engine)
- [ ] NVM, Node.js, npm
- [ ] Git + repo clone

---

---

## Running the Script from a ZIP Download (Sandbox Method)

1. Inside the Sandbox, open a browser and download the ZIP version of the repo from GitHub.

2. Extract the ZIP file.

3. Open PowerShell **as Administrator**.

4. Run the following commands:
   ```powershell
   Set-ExecutionPolicy Bypass -Scope Process -Force
   cd "$env:USERPROFILE\Downloads\windows-sandbox-dev-setup-main"
   .\sandbox-setup.ps1
   ```

This will install all tools and clone your repo in one go.

---


## How to Use

### Prerequisites
- Windows 10/11 **Pro or Enterprise**
- Enable **Windows Sandbox**  
  - Go to “Turn Windows features on or off”  
  - Enable: `Windows Sandbox`

---

### Step 1: Download This Repo
```bash
git clone https://github.com/YOUR_USERNAME/windows-sandbox-dev-setup.git
```

---

### Step 2: Run the Sandbox
Double-click the provided `.wsb` file:
```
WindowsDevEnv.wsb
```

This will:
- Launch a new Windows Sandbox
- Automatically run the PowerShell script
- Install all the tools for you

---

### Step 3: (Optional) Set Up WSL2
After setting up your host, run the `wsl-setup.sh` script inside your WSL Ubuntu environment.

```bash
cd windows-sandbox-dev-setup
bash wsl-setup.sh
```

---

## Repo Structure

```
.
├── sandbox-setup.ps1     # Windows install script
├── wsl-setup.sh          # WSL2 install script
├── WindowsDevEnv.wsb     # Sandbox config file with automation
├── README.md             # You're here
```

---

## Why Use This?

This setup is:
- Reproducible
- Perfect for recording YouTube DevOps content
- Disposable — break it, close it, start fresh

---

## License

MIT. Use it, modify it, break it — don’t sell it without adding value.
