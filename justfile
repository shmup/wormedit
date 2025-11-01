# Build wormscaler.exe from PowerShell script

set shell := ["powershell.exe", "-Command"]

build:
    if (-not (Get-Module -ListAvailable -Name ps2exe)) { Install-Module -Name ps2exe -Scope CurrentUser -Force }
    Invoke-ps2exe -inputFile wormscaler.ps1 -outputFile wormscaler.exe -noConsole -title 'Worms Armageddon Scaler' -version '1.0.0.0'

clean:
    if (Test-Path wormscaler.exe) { Remove-Item wormscaler.exe }
