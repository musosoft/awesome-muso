## Make Windows Updates Optional on Windows 11
To make Windows updates optional, you can modify the Windows Registry. Run the following PowerShell commands as an Administrator:

```powershell
# Navigate to the WindowsUpdate key or create it if it doesn't exist
Set-Location -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows"
if (-Not (Test-Path "WindowsUpdate")) {
    New-Item -Path "WindowsUpdate"
}

# Navigate to the AU key or create it if it doesn't exist
Set-Location -Path "WindowsUpdate"
if (-Not (Test-Path "AU")) {
    New-Item -Path "AU"
}

# Create AUOptions and set DWORD value to 2
Set-Location -Path "AU"
Set-ItemProperty -Path . -Name "AUOptions" -Value 2
```