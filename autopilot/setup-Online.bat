@echo off
PowerShell.exe -NoProfile -Command "& {Start-Process PowerShell.exe -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File ""%~dp0\AutopilotEnrollment-Online.ps1""' -Verb RunAs}"
