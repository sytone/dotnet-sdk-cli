@ECHO OFF
powershell -NoLogo -NoProfile -ExecutionPolicy Unrestricted -File "%~dpn0.ps1" %*
