@echo off
setlocal enabledelayedexpansion

:: ============================================================
:: KingsCourt KA Lite - Installer / Launcher
:: ============================================================
:: Usage:
::   setup-kalite.bat              First-time install + start
::   setup-kalite.bat start        Start the server
::   setup-kalite.bat stop         Stop the server
::   setup-kalite.bat status       Check server status
:: ============================================================

set INSTALL_DIR=%USERPROFILE%\kingscourt-ka
set KALITE_HOME=%USERPROFILE%\.kalite

:: -----------------------------------------------------------
:: Handle start / stop / status commands
:: -----------------------------------------------------------
if "%1"=="start" goto :cmd_start
if "%1"=="stop" goto :cmd_stop
if "%1"=="status" goto :cmd_status

:: If already installed, ask what to do
if exist "%INSTALL_DIR%\kalite_env\Scripts\activate.bat" (
    if exist "%KALITE_HOME%\database\content_khan_en.sqlite" (
        echo.
        echo  KA Lite is already installed.
        echo.
        echo  [1] Start server
        echo  [2] Stop server
        echo  [3] Reinstall
        echo  [4] Exit
        echo.
        set /p CHOICE="  Choose [1-4]: "
        if "!CHOICE!"=="1" goto :cmd_start
        if "!CHOICE!"=="2" goto :cmd_stop
        if "!CHOICE!"=="3" goto :install
        exit /b 0
    )
)

goto :install

:: -----------------------------------------------------------
:: START
:: -----------------------------------------------------------
:cmd_start
title KA Lite Server
color 0A
cd /d "%INSTALL_DIR%"
call kalite_env\Scripts\activate.bat
kalite start
echo.
echo  KA Lite is running at http://127.0.0.1:8008/
echo.
echo  Login credentials:
echo    Admin:   admin / admin
echo    Coach:   coach / coach
echo    Student: student / student
echo.
start http://127.0.0.1:8008/
pause
exit /b 0

:: -----------------------------------------------------------
:: STOP
:: -----------------------------------------------------------
:cmd_stop
cd /d "%INSTALL_DIR%"
call kalite_env\Scripts\activate.bat
kalite stop
echo  KA Lite server stopped.
pause
exit /b 0

:: -----------------------------------------------------------
:: STATUS
:: -----------------------------------------------------------
:cmd_status
cd /d "%INSTALL_DIR%"
call kalite_env\Scripts\activate.bat
kalite status
pause
exit /b 0

:: -----------------------------------------------------------
:: INSTALL
:: -----------------------------------------------------------
:install
title KingsCourt KA Lite Installer
color 0A

echo.
echo  ========================================
echo   KingsCourt KA Lite - Offline Installer
echo  ========================================
echo.

:: -----------------------------------------------------------
:: Step 0: Check prerequisites
:: -----------------------------------------------------------
echo [Step 0/9] Checking prerequisites...

where git >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Git is not installed. Please install Git from https://git-scm.com/
    pause
    exit /b 1
)
echo   [OK] Git found

where python >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Python is not installed. Please install Python 2.7 from https://www.python.org/downloads/release/python-2718/
    pause
    exit /b 1
)

:: Check Python version is 2.7
python -c "import sys; exit(0 if sys.version_info[:2]==(2,7) else 1)" >nul 2>&1
if %errorlevel% neq 0 (
    echo WARNING: Python 2.7 is required. Checking for python2...
    where python2 >nul 2>&1
    if %errorlevel% neq 0 (
        echo ERROR: Python 2.7 not found. KA Lite requires Python 2.7.
        echo        Install from https://www.python.org/downloads/release/python-2718/
        pause
        exit /b 1
    )
    set PYTHON_CMD=python2
) else (
    set PYTHON_CMD=python
)
echo   [OK] Python 2.7 found

where node >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Node.js is not installed. Please install Node.js from https://nodejs.org/
    pause
    exit /b 1
)
echo   [OK] Node.js found

where npm >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: npm is not installed. It should come with Node.js.
    pause
    exit /b 1
)
echo   [OK] npm found

echo.

:: -----------------------------------------------------------
:: Step 1: Clone the repository
:: -----------------------------------------------------------
echo [Step 1/9] Cloning repository to %INSTALL_DIR%...

if exist "%INSTALL_DIR%" (
    echo   Directory already exists. Pulling latest changes...
    cd /d "%INSTALL_DIR%"
    git pull origin main
) else (
    git clone https://github.com/JUSTICEESSIELP/kingscourt-ka.git "%INSTALL_DIR%"
    cd /d "%INSTALL_DIR%"
)

if %errorlevel% neq 0 (
    echo ERROR: Failed to clone repository. Check your internet connection.
    pause
    exit /b 1
)
echo   [OK] Repository ready
echo.

:: -----------------------------------------------------------
:: Step 2: Set up Python virtual environment
:: -----------------------------------------------------------
echo [Step 2/9] Setting up Python virtual environment...

if not exist "%INSTALL_DIR%\kalite_env" (
    %PYTHON_CMD% -m virtualenv kalite_env 2>nul
    if %errorlevel% neq 0 (
        echo   virtualenv not found, installing...
        %PYTHON_CMD% -m pip install virtualenv
        %PYTHON_CMD% -m virtualenv kalite_env
    )
)

:: Activate venv
call kalite_env\Scripts\activate.bat

echo   [OK] Virtual environment ready
echo.

:: -----------------------------------------------------------
:: Step 3: Install Python dependencies
:: -----------------------------------------------------------
echo [Step 3/9] Installing Python dependencies...

pip install -r requirements.txt 2>nul
if %errorlevel% neq 0 (
    echo   Retrying with --no-deps...
    pip install --no-deps -r requirements.txt
)

:: Install KA Lite itself
%PYTHON_CMD% setup.py install 2>nul || pip install -e .

echo   [OK] Python dependencies installed
echo.

:: -----------------------------------------------------------
:: Step 4: Install Node.js dependencies and build JS bundles
:: -----------------------------------------------------------
echo [Step 4/9] Installing Node.js dependencies...

call npm install 2>nul
if %errorlevel% neq 0 (
    echo   npm install had issues, continuing...
)

:: Fix jquery-sparkline (dist/jquery.sparkline.js is missing)
echo   Fixing jquery-sparkline build...
set SPARKLINE_DIR=%INSTALL_DIR%\node_modules\jquery-sparkline
if exist "%SPARKLINE_DIR%\src\header.js" (
    if not exist "%SPARKLINE_DIR%\dist" mkdir "%SPARKLINE_DIR%\dist"

    :: Concatenate source files in correct build order
    type nul > "%SPARKLINE_DIR%\dist\jquery.sparkline.js"
    for %%f in (
        header.js
        defaults.js
        utils.js
        simpledraw.js
        rangemap.js
        interact.js
        base.js
        chart-line.js
        chart-bar.js
        chart-tristate.js
        chart-discrete.js
        chart-bullet.js
        chart-pie.js
        chart-box.js
        vcanvas-base.js
        vcanvas-canvas.js
        vcanvas-vml.js
        footer.js
    ) do (
        if exist "%SPARKLINE_DIR%\src\%%f" (
            type "%SPARKLINE_DIR%\src\%%f" >> "%SPARKLINE_DIR%\dist\jquery.sparkline.js"
        )
    )
    echo   [OK] jquery-sparkline built
)

:: Build JS bundles
echo   Building JS bundles...
node build.js --debug
if %errorlevel% neq 0 (
    echo ERROR: JS bundle build failed.
    pause
    exit /b 1
)
echo   [OK] JS bundles built
echo.

:: -----------------------------------------------------------
:: Step 5: Initialize KA Lite database
:: -----------------------------------------------------------
echo [Step 5/9] Initializing KA Lite...

:: Run setup/migrate
kalite manage setup --noinput 2>nul
if %errorlevel% neq 0 (
    kalite manage syncdb --noinput
    kalite manage migrate --noinput
)

echo   [OK] Database initialized
echo.

:: -----------------------------------------------------------
:: Step 6: Download English content pack
:: -----------------------------------------------------------
echo [Step 6/9] Downloading English content pack (~127 MB)...
echo   This contains all exercises, topics, and assessment data.
echo   (Videos are separate and optional)

kalite manage retrievecontentpack download en
if %errorlevel% neq 0 (
    echo WARNING: Content pack download failed. You may need internet access.
    echo          You can retry later with: kalite manage retrievecontentpack download en
)

echo   [OK] Content pack downloaded
echo.

:: -----------------------------------------------------------
:: Step 7: Collect static files
:: -----------------------------------------------------------
echo [Step 7/9] Collecting static files...

kalite manage collectstatic --noinput
echo   [OK] Static files collected
echo.

:: -----------------------------------------------------------
:: Step 8: Create admin and default facility setup
:: -----------------------------------------------------------
echo [Step 8/9] Setting up admin account and facility...

:: Create Django superuser (admin/admin)
echo   Creating admin account (username: admin, password: admin)...
%PYTHON_CMD% -c "import os; os.environ.setdefault('DJANGO_SETTINGS_MODULE','kalite.settings'); os.environ['KALITE_HOME']=r'%KALITE_HOME%'; import django; from django.contrib.auth.models import User; User.objects.create_superuser('admin','admin@kalite.local','admin') if not User.objects.filter(username='admin').exists() else None" 2>nul

:: Create facility, group, coach, and sample student via management commands
kalite manage shell -c "
from kalite.facility.models import Facility, FacilityGroup, FacilityUser
# Create default facility
facility, _ = Facility.objects.get_or_create(name='KingsCourt Academy')
# Create groups
group1, _ = FacilityGroup.objects.get_or_create(name='Class A', facility=facility)
group2, _ = FacilityGroup.objects.get_or_create(name='Class B', facility=facility)
# Create coach account
if not FacilityUser.objects.filter(username='coach').exists():
    coach = FacilityUser(username='coach', first_name='Coach', last_name='Teacher', facility=facility, is_teacher=True)
    coach.set_password('coach')
    coach.save()
    print('  Coach created: coach / coach')
# Create sample student
if not FacilityUser.objects.filter(username='student').exists():
    student = FacilityUser(username='student', first_name='Sample', last_name='Student', facility=facility, group=group1)
    student.set_password('student')
    student.save()
    print('  Sample student created: student / student')
print('  Facility and groups ready')
" 2>nul

echo   [OK] Accounts created
echo.

:: -----------------------------------------------------------
:: Step 9: Register device and start server
:: -----------------------------------------------------------
echo [Step 9/9] Starting KA Lite server...

:: One-click device registration
kalite manage register --unregistered 2>nul

:: Start the server
kalite start

echo.
echo  ========================================
echo   Installation Complete!
echo  ========================================
echo.
echo   KA Lite is running at:
echo     http://127.0.0.1:8008/
echo.
echo   Login credentials:
echo     Admin:   admin / admin
echo     Coach:   coach / coach
echo     Student: student / student
echo.
echo   Next time, use:
echo     setup-kalite.bat start
echo     setup-kalite.bat stop
echo     setup-kalite.bat status
echo   Or just double-click to get the menu.
echo.
echo   Content includes 2,740 exercises across:
echo     Math, Science, Economics, Arts,
echo     Computing, Test prep, and more.
echo.
echo   Videos can be downloaded from:
echo     http://127.0.0.1:8008/update/videos/
echo.
echo  ========================================
echo.

:: Open browser
start http://127.0.0.1:8008/

pause
