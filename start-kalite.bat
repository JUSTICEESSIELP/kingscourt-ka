@echo off
title KA Lite Server
color 0A

echo Starting KA Lite...
cd /d "%USERPROFILE%\kingscourt-ka"
call kalite_env\Scripts\activate.bat
kalite start

echo.
echo KA Lite is running at http://127.0.0.1:8008/
echo Press any key to open in browser...
pause >nul
start http://127.0.0.1:8008/
