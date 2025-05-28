# Setting up Multipass

## Install for Linux/macOS

```bash
curl -fsSL "https://raw.githubusercontent.com/nucamp/defsec/refs/heads/main/unix-setup/setup.sh" | bash
```


## Install for windows

```powershell
Invoke-Expression (Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/nucamp/defsec/refs/heads/main/windows-setup/setup.ps1" | Select-Object -ExpandProperty Content)
```
