# PowerShell script to set up nucamp VMs using multipass

Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

choco install virtualbox

choco install multipass


# Ensure multipass is installed (assuming it's available on the system)
if (-not (Get-Command multipass -ErrorAction SilentlyContinue)) {
    Write-Host "Multipass is not installed. Please install it first."
    exit 1
}

# Get running instances
$currentInstances = multipass list --format json | ConvertFrom-Json
$currentCount = $currentInstances.list.Count
$currentNames = $currentInstances.list | Select-Object -ExpandProperty name

Write-Host @"
Hey there!!

Imma just be over here setting up nucamp VMs on your machine :) I will be sure
to let you know all the things that I am doing

"@

Start-Sleep -Seconds 10

# Check for Homebrew (not typical on Windows, so we assume a package manager or skip for Windows)
$hb = Get-Command brew -ErrorAction SilentlyContinue
if (-not $hb) {
    Write-Host @"

The very first thing that I am going to do is ensure that you have the winget package manager
installed on your computer (Homebrew is more common on macOS/Linux).

"@
    # For Windows, winget is typically pre-installed on modern systems
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Host "Winget is not installed. Please install it manually or use another package manager."
        exit 1
    }
}

Start-Sleep -Seconds 10

Write-Host @"

Ok, first I will check if you already have multipass machines running on your
computer. This will help avoid potential naming conflicts.

"@

Start-Sleep -Seconds 10

if ($currentCount -gt 0) {
    Write-Host "Hey look, I found some!`n"
}

$newMachines = @("nucamp-ubuntu-machine-1", "nucamp-ubuntu-machine-2")

Write-Host @"

Ok, now that I know that you have machines already running, I will check for
naming conflicts. Our machines will be called:

- nucamp-ubuntu-machine-1
- nucamp-ubuntu-machine-2

Just FYI, if I find naming conflicts I will exit out...

"@

Start-Sleep -Seconds 10

# Check for existing machines and exit on name conflicts
foreach ($name in $newMachines) {
    if ($currentNames -contains $name) {
        Write-Host "`n[!] Found name conflict. Machine already exists with name $name"
        Write-Host @"

You may be wondering what to do now that I have found conflicts. Well, if you
still need the machine with the conflicting name ($name), you can rename the
machine with the following command:

multipass clone $name --name <your new name here>

Then, you can delete and purge the old machine with:

multipass delete $name && multipass purge

"@
        exit 1
    }
}

Write-Host @"

Ok, so good news; I did not find any name conflicts so we are good
to go ahead and create the machines without an issue

"@

# Create new instances with specified features
foreach ($name in $newMachines) {
    multipass launch --cpus 2 --memory 2G --name $name 24.04 --disk 20GB
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Ruh roh! Something is all screwy and I could not create the machine $name!"
        exit 1
    }
}

Write-Host @"

Ok! That worked! Now I will do some basic health checks and configuration to be
sure everything will work as expected.

"@

# Network health checks
Write-Host @"

First up, I need to make sure that each VM has access to the internet, this is
required in order to update the VM and install software packages. The command
I will run is:

multipass exec <vm name> -- ping -c 3 1.1.1.1

This command will 'ping' Cloudflare's DNS servers 3 times. This
way we know that we can reach the WAN (wide area network)

"@

foreach ($name in $newMachines) {
    multipass exec $name -- ping -c 3 1.1.1.1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Ruh roh! Something is all screwy and I could not verify network for $name!"
        exit 1
    }
}

Write-Host @"

Looks like the network is setup correctly!

Now I will setup the hacking machine with all the tools that you will need.

You are about to see a lot of stuff whiz by!!

"@

Start-Sleep -Seconds 10

# Transfer and execute setup script (assuming ./kali/setup.sh exists locally)
if (Test-Path ./kali/setup.sh) {
    multipass transfer ./kali/setup.sh nucamp-ubuntu-machine-2:/home/ubuntu/setup.sh
    multipass exec nucamp-ubuntu-machine-2 -- sudo bash /home/ubuntu/setup.sh
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Hmmm.... Something went haywire with that setup."
        Write-Host "The machine will still work but will need some help getting set up the rest of the way"
        exit 1
    }
} else {
    Write-Host "Error: ./kali/setup.sh not found locally."
    exit 1
}

Write-Host @"

That's it! I am done

"@
