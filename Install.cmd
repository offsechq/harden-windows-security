@echo off
:: Launcher for Install.ps1 - bypasses execution policy automatically
:: This allows users to double-click to install without changing system settings

cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\Install.ps1"
