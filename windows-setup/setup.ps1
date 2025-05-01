# Custom Safe-Sleep function
function Safe-Sleep {
    param (
        [int]$seconds = 0
    )

    if ($seconds -gt 0) {
        Start-Sleep -Seconds $seconds
    }
}

# Set execution policy and install Chocolatey with secure TLS
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))


# Install VirtualBox and Multipass via Chocolatey
choco install virtualbox -y
choco install multipass --params="'/HyperVisor:VirtualBox'" -y

# Wait a few seconds to ensure install completes
Safe-Sleep 5

# Ensure multipass is installed and available in the session
if (-not (Get-Command multipass -ErrorAction SilentlyContinue)) {
    Write-Host "`n[!] Multipass is not installed or not in PATH yet. Try restarting your PowerShell session."
    Pause
    exit 1
}

# Optionally purge old deleted instances
multipass purge

# Get current instances
$currentInstances = multipass list --format json | ConvertFrom-Json
$currentCount = $currentInstances.list.Count
$currentNames = $currentInstances.list | Select-Object -ExpandProperty name

Write-Host @"
Hey there!!

Imma just be over here setting up nucamp VMs on your machine :) I will be sure
to let you know all the things that I am doing

"@

Safe-Sleep 5

Write-Host @"
Ok, first I will check if you already have multipass machines running on your
computer. This will help avoid potential naming conflicts.
"@

Safe-Sleep 5

if ($currentCount -gt 0) {
    Write-Host "`nHey look, I found some running instances!`n"
    $currentNames | ForEach-Object { Write-Host " - $_" }
}

$newMachines = @("nucamp-ubuntu-machine-1", "nucamp-ubuntu-machine-2")

Write-Host @"
Now I will check for naming conflicts.
The machines I plan to create are:

- nucamp-ubuntu-machine-1
- nucamp-ubuntu-machine-2

If I find a conflict, I will tell you how to fix it.

"@

Safe-Sleep 5

# Check for existing machines and exit on conflict
foreach ($name in $newMachines) {
    if ($currentNames -contains $name) {
        Write-Host "`n[!] Found name conflict: $name already exists!"
        Write-Host @"
You can fix this by renaming or deleting the existing VM.

Rename:
multipass clone $name --name <your-new-name>

Delete and purge:
multipass delete $name && multipass purge
"@
        Pause
        exit 1
    }
}

Write-Host "`nNo conflicts found! Creating your VMs now..."
Safe-Sleep 3

foreach ($name in $newMachines) {
    multipass launch --cpus 2 --memory 2G --name $name 24.04 --disk 20GB
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[!] Failed to create machine: $name"
        Pause
        exit 1
    }
}

Write-Host @"
✔ All machines created successfully!

Now I will check if each VM can reach the internet by pinging 1.1.1.1...
"@

foreach ($name in $newMachines) {
    Write-Host "`nChecking network for $name..."
    multipass exec $name -- ping -c 3 1.1.1.1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[!] Network check failed for $name!"
        Pause
        exit 1
    }
}

Write-Host @"
✔ Network looks good!

Now downloading and executing the setup script on the hacking machine...
"@

Safe-Sleep 3

# Download setup script
Invoke-WebRequest -Uri "https://gist.githubusercontent.com/DavidHoenisch/76d72f543aa5afbd58aa5f1e58694535/raw/ba46befd5d9ba54421240271b97c40be391cc5f3/setup.sh" -OutFile "ubuntu_setup.sh"

# Verify the download
if (Test-Path ./ubuntu_setup.sh) {
    multipass transfer ./ubuntu_setup.sh nucamp-ubuntu-machine-2:/home/ubuntu/setup.sh
    multipass exec nucamp-ubuntu-machine-2 -- sudo bash /home/ubuntu/setup.sh
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[!] Something went wrong with the setup script execution!"
        Pause
        exit 1
    }
} else {
    Write-Host "[!] Failed to download setup.sh. Please check your internet connection."
    Pause
    exit 1
}

Write-Host @"
🎉 Done setting up your VMs!

You're all set. If you run into issues, rerun this script or check logs inside the VMs.
"@

Pause
