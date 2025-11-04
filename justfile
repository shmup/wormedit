# Build wormedit.exe from PowerShell script

set shell := ["powershell.exe", "-Command"]

build:
    if (-not (Get-Module -ListAvailable -Name ps2exe)) { Install-Module -Name ps2exe -Scope CurrentUser -Force }
    Invoke-ps2exe -inputFile wormedit.ps1 -outputFile wormedit.exe -noConsole -title 'Worms Armageddon Scaler' -version '1.0.0.0' -iconFile icon.ico

clean:
    if (Test-Path wormedit.exe) { Remove-Item wormedit.exe }
