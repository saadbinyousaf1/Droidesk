@echo off
rem // © https://saadbinyousaf.dev/ © //
start "" conhost.exe --headless powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -STA -File "%~dp0core\server.ps1"
rem // © https://saadbinyousaf.dev/ © //
