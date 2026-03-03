@echo off
cd /d "%USERPROFILE%\kingscourt-ka"
call kalite_env\Scripts\activate.bat
kalite stop
echo KA Lite server stopped.
pause
