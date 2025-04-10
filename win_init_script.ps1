Set-MpPreference -DisableRealtimeMonitoring $true
netsh advfirewall set allprofiles state off
New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Office\16.0\Word' -Force | Out-Null
New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Office\16.0\Word\Security' -Force | Out-Null
New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Office\16.0\Word\Security' -Name 'VBAWarnings' -PropertyType DWord -Value 1 -Force
Invoke-WebRequest -Uri 'https://dl.google.com/chrome/install/latest/chrome_installer.exe' -OutFile 'C:\chrome_installer.exe'
Start-Process -FilePath 'C:\chrome_installer.exe' -ArgumentList '/silent /install' -Wait
Remove-Item 'C:\chrome_installer.exe'
