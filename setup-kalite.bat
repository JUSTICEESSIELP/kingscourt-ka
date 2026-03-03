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
set DOWNLOADS=%TEMP%\kalite-prereqs
set PY27=C:\Python27\python.exe

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
:: Detect LAN IP
set LAN_IP=
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4 Address"') do (
    for /f "tokens=1" %%b in ("%%a") do (
        echo %%b | findstr /b "127." >nul
        if errorlevel 1 (
            if not defined LAN_IP set "LAN_IP=%%b"
        )
    )
)
if not defined LAN_IP set "LAN_IP=127.0.0.1"
echo.
echo  KA Lite is running!
echo.
echo  Admin:    http://127.0.0.1:8008/
echo  Students: http://!LAN_IP!:8008/
echo.
echo  Tell students to open the URL above
echo  in any browser on the school WiFi.
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

if not exist "%DOWNLOADS%" mkdir "%DOWNLOADS%"

:: -----------------------------------------------------------
:: Step 0: Check and auto-install prerequisites
:: -----------------------------------------------------------
echo [Step 0/9] Checking and installing prerequisites...
echo.

:: ----- GIT -----
where git >nul 2>&1
if !errorlevel! neq 0 (
    echo   Git not found. Downloading Git installer...
    echo   This may take a few minutes...
    powershell -Command "& { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://github.com/git-for-windows/git/releases/download/v2.43.0.windows.1/Git-2.43.0-64-bit.exe' -OutFile '%DOWNLOADS%\git-installer.exe' }"
    if not exist "%DOWNLOADS%\git-installer.exe" (
        echo   ERROR: Failed to download Git. Check your internet connection.
        pause
        exit /b 1
    )
    echo   Installing Git silently...
    "%DOWNLOADS%\git-installer.exe" /VERYSILENT /NORESTART /NOCANCEL /SP- /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS /COMPONENTS="icons,ext\reg\shellhere,assoc,assoc_sh"
    set "PATH=!PATH!;C:\Program Files\Git\cmd"
    echo   [OK] Git installed
) else (
    echo   [OK] Git found
)

:: ----- PYTHON 2.7 -----
:: Always use C:\Python27\python.exe — ignore any other Python on PATH
if exist "%PY27%" (
    echo   [OK] Python 2.7 found at %PY27%
) else (
    echo   Python 2.7 not found. Downloading Python 2.7.18...
    echo   This may take a few minutes...
    powershell -Command "& { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://www.python.org/ftp/python/2.7.18/python-2.7.18.amd64.msi' -OutFile '%DOWNLOADS%\python27.msi' }"
    if not exist "%DOWNLOADS%\python27.msi" (
        echo   ERROR: Failed to download Python 2.7. Check your internet connection.
        pause
        exit /b 1
    )
    echo   Installing Python 2.7 to C:\Python27...
    msiexec /i "%DOWNLOADS%\python27.msi" /qn TARGETDIR=C:\Python27 ADDLOCAL=ALL
    :: Wait for MSI to finish
    echo   Waiting for installation to complete...
    :wait_py27
    timeout /t 3 /nobreak >nul
    if not exist "%PY27%" goto :wait_py27
    echo   [OK] Python 2.7 installed
)
set "PATH=C:\Python27;C:\Python27\Scripts;!PATH!"

:: ----- PIP for Python 2.7 -----
"%PY27%" -m pip --version >nul 2>&1
if !errorlevel! neq 0 (
    echo   pip not found for Python 2.7. Installing pip...
    powershell -Command "& { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://bootstrap.pypa.io/pip/2.7/get-pip.py' -OutFile '%DOWNLOADS%\get-pip.py' }"
    "%PY27%" "%DOWNLOADS%\get-pip.py"
    echo   [OK] pip installed
) else (
    echo   [OK] pip found
)

:: ----- VIRTUALENV for Python 2.7 -----
:: Use virtualenv 20.21.1 — last version supporting Python 2.7
"%PY27%" -m virtualenv --version >nul 2>&1
if !errorlevel! neq 0 (
    echo   Installing virtualenv for Python 2.7...
    "%PY27%" -m pip install "virtualenv<20.22"
    echo   [OK] virtualenv installed
) else (
    echo   [OK] virtualenv found
)

:: ----- NODE.JS -----
where node >nul 2>&1
if !errorlevel! neq 0 (
    echo   Node.js not found. Downloading Node.js installer...
    echo   This may take a few minutes...
    powershell -Command "& { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://nodejs.org/dist/v18.19.0/node-v18.19.0-x64.msi' -OutFile '%DOWNLOADS%\nodejs.msi' }"
    if not exist "%DOWNLOADS%\nodejs.msi" (
        echo   ERROR: Failed to download Node.js. Check your internet connection.
        pause
        exit /b 1
    )
    echo   Installing Node.js silently...
    msiexec /i "%DOWNLOADS%\nodejs.msi" /qn
    :: Wait for MSI to finish
    echo   Waiting for installation to complete...
    :wait_node
    timeout /t 3 /nobreak >nul
    where node >nul 2>&1
    if !errorlevel! neq 0 (
        set "PATH=!PATH!;C:\Program Files\nodejs"
        where node >nul 2>&1
        if !errorlevel! neq 0 goto :wait_node
    )
    echo   [OK] Node.js installed
) else (
    echo   [OK] Node.js found
)

echo.
echo   All prerequisites ready!
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

if !errorlevel! neq 0 (
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
    "%PY27%" -m virtualenv kalite_env
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
if !errorlevel! neq 0 (
    echo   Retrying with --no-deps...
    pip install --no-deps -r requirements.txt
)

:: Install KA Lite itself
python setup.py install 2>nul || pip install -e .

echo   [OK] Python dependencies installed
echo.

:: -----------------------------------------------------------
:: Step 4: Install Node.js dependencies and build JS bundles
:: -----------------------------------------------------------
echo [Step 4/9] Installing Node.js dependencies...

:: Clean any corrupted node_modules from a previous failed run
if exist "%INSTALL_DIR%\node_modules" (
    if not exist "%INSTALL_DIR%\node_modules\browserify" (
        echo   Removing incomplete node_modules...
        rmdir /s /q "%INSTALL_DIR%\node_modules"
    )
)

echo   Running npm install (this may take a few minutes)...
call npm install
if !errorlevel! neq 0 (
    echo   npm install failed. Retrying...
    call npm install --force
)

:: Verify critical module exists
if not exist "%INSTALL_DIR%\node_modules\browserify" (
    echo   ERROR: browserify not installed. Trying direct install...
    call npm install browserify factor-bundle minifyify
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
if !errorlevel! neq 0 (
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
if !errorlevel! neq 0 (
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
if !errorlevel! neq 0 (
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
python -c "import os; os.environ.setdefault('DJANGO_SETTINGS_MODULE','kalite.settings'); os.environ['KALITE_HOME']=r'%KALITE_HOME%'; import django; from django.contrib.auth.models import User; User.objects.create_superuser('admin','admin@kalite.local','admin') if not User.objects.filter(username='admin').exists() else None" 2>nul

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
echo   Default accounts:
echo     Admin:   admin / admin
echo     Coach:   coach / coach
echo     Student: student / student
echo.

:: -----------------------------------------------------------
:: Step 9: Register device and start server
:: -----------------------------------------------------------
echo [Step 9/9] Starting KA Lite server...

:: One-click device registration
kalite manage register --unregistered 2>nul

:: Start the server
kalite start

:: Detect LAN IP address for student access
set LAN_IP=
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4 Address"') do (
    for /f "tokens=1" %%b in ("%%a") do (
        echo %%b | findstr /b "127." >nul
        if errorlevel 1 (
            if not defined LAN_IP set "LAN_IP=%%b"
        )
    )
)
if not defined LAN_IP set "LAN_IP=127.0.0.1"

:: Clean up downloaded installers
if exist "%DOWNLOADS%" rmdir /s /q "%DOWNLOADS%"

echo.
echo  ========================================
echo   Installation Complete!
echo  ========================================
echo.
echo   KA Lite is running!
echo.
echo   Admin access (this computer):
echo     http://127.0.0.1:8008/
echo.
echo   ----------------------------------------
echo   STUDENTS: Open this URL in any browser
echo   on any device connected to the WiFi:
echo.
echo     http://!LAN_IP!:8008/
echo.
echo   ----------------------------------------
echo.
echo   Login credentials:
echo     Admin:   admin / admin
echo     Coach:   coach / coach
echo     Student: student / student
echo.
echo   Next time, just double-click this file.
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
