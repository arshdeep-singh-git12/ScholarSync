@echo off
setlocal enabledelayedexpansion
title ScholarSync - Multi-Portal Academic Platform
color 0B

:: -------------------------------------------------------------------------
:: 1. Resolve Project Root Directory
:: -------------------------------------------------------------------------
set "BASE_DIR=%~dp0"
set "PROJECT_ROOT=%BASE_DIR%"
set "ENV_FILE=%BASE_DIR%.env"
set "PROP_FILE=%PROJECT_ROOT%backend\src\main\resources\application.properties"
set "SERVER_SCRIPT=%PROJECT_ROOT%frontend\serve_portals.py"

:: -------------------------------------------------------------------------
:: 2. Read or Prompt for Credentials (.env)
:: -------------------------------------------------------------------------
cls
echo ========================================================================
echo        ScholarSync: Multi-Portal Academic Registration Platform
echo ========================================================================
echo.

set "SUPABASE_PROJECT_REF="
set "SUPABASE_DB_PASSWORD="

if exist "%ENV_FILE%" (
    for /f "usebackq eol=# tokens=1,* delims==" %%A in ("%ENV_FILE%") do (
        set "KEY=%%A"
        set "VAL=%%B"
        for /f "tokens=* delims= " %%K in ("!KEY!") do set "KEY=%%K"
        for /f "tokens=* delims= " %%V in ("!VAL!") do set "VAL=%%V"
        if /i "!KEY!"=="SUPABASE_PROJECT_REF" set "SUPABASE_PROJECT_REF=!VAL!"
        if /i "!KEY!"=="SUPABASE_DB_PASSWORD" set "SUPABASE_DB_PASSWORD=!VAL!"
    )
)

if "!SUPABASE_PROJECT_REF!"=="" (
    echo ====================================================================
    echo   First Time Setup: Supabase Cloud Credentials Required
    echo ====================================================================
    echo   Credentials will be saved to .env and will NEVER be asked again.
    echo.
    set /p SUPA_REF="  Enter Supabase Project Ref (e.g. abcdefghijklmnopqrst): "
    set /p SUPA_PASS="  Enter Supabase Database Password: "
    
    if not "!SUPA_REF!"=="" set "SUPABASE_PROJECT_REF=!SUPA_REF!"
    if not "!SUPA_PASS!"=="" set "SUPABASE_DB_PASSWORD=!SUPA_PASS!"
    
    (
        echo # ScholarSync Environment Configuration
        echo SUPABASE_PROJECT_REF=!SUPABASE_PROJECT_REF!
        echo SUPABASE_DB_PASSWORD=!SUPABASE_DB_PASSWORD!
    ) > "%ENV_FILE%"
    echo.
    echo [SUCCESS] Saved credentials to .env file!
    echo.
)

:: Sync into application.properties
if exist "%PROP_FILE%" (
    if not "!SUPABASE_PROJECT_REF!"=="" (
        powershell -NoProfile -Command "(Get-Content '%PROP_FILE%') -replace 'db\.[^.]+\.supabase\.co', 'db.!SUPABASE_PROJECT_REF!.supabase.co' | Set-Content '%PROP_FILE%'"
    )
    if not "!SUPABASE_DB_PASSWORD!"=="" (
        powershell -NoProfile -Command "(Get-Content '%PROP_FILE%') -replace 'YOUR_SUPABASE_PASSWORD', '!SUPABASE_DB_PASSWORD!' | Set-Content '%PROP_FILE%'"
    )
)

:: -------------------------------------------------------------------------
:: 3. Terminate Lingering Port Processes (8080, 5500-5504)
:: -------------------------------------------------------------------------
echo [1/3] Stopping any previous background sessions...
powershell -NoProfile -Command "Get-NetTCPConnection -LocalPort 8080, 5500, 5501, 5502, 5503, 5504 -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess -Unique | ForEach-Object { Stop-Process -Id $_ -Force -ErrorAction SilentlyContinue }" >nul 2>&1
timeout /t 1 /nobreak >nul

:: -------------------------------------------------------------------------
:: 4. Locate Bundled Maven
:: -------------------------------------------------------------------------
set "MVN_CMD="
if exist "%BASE_DIR%maven\bin\mvn.cmd" (
    set "MVN_CMD=%BASE_DIR%maven\bin\mvn.cmd"
) else (
    set "MVN_CMD=mvn"
)

:: -------------------------------------------------------------------------
:: 5. Launch Backend & Multi-Port Frontend Server
:: -------------------------------------------------------------------------
echo [2/3] Launching Spring Boot REST API on port 8080...
start "ScholarSync Backend API" cmd /k "cd /d "%PROJECT_ROOT%backend" && "!MVN_CMD!" spring-boot:run"

echo [3/3] Launching Multi-Portal Web Server (Ports 5500, 5501, 5502, 5503, 5504)...
start "ScholarSync Multi-Portal Server" cmd /k "python "%SERVER_SCRIPT%""

echo.
echo [OK] All servers started successfully!
echo Loading Control Menu (Browser will NOT open automatically)...
timeout /t 2 /nobreak >nul

:: -------------------------------------------------------------------------
:: 6. Interactive Multi-Portal Control Menu
:: -------------------------------------------------------------------------
:MENU
cls
color 0A
echo ========================================================================
echo                 ScholarSync: Multi-Portal Control Center
echo ========================================================================
echo.
echo  ALL PORTALS CONNECTED TO CENTRAL BACKEND (http://localhost:8080/api):
echo.
echo    [1] Student Portal        --^> http://localhost:5501
echo    [2] Admin Console         --^> http://localhost:5502
echo    [3] Registrar Portal      --^> http://localhost:5503
echo    [4] Certificate Verify    --^> http://localhost:5504
echo    [5] Main Gateway (Login)  --^> http://localhost:5500
echo.
echo    [A] Open ALL Portals in separate browser tabs at once
echo.
echo ------------------------------------------------------------------------
echo  DEMO CREDENTIALS:
echo    - Admin:      admin     / admin123
echo    - Registrar:  registrar / registrar123
echo    - Student:    student   / student123  (or self-register)
echo ------------------------------------------------------------------------
echo    [0] Stop All Servers and Exit
echo ========================================================================
echo.
set /p OPT="Select an option (0-5, A): "

if /i "%OPT%"=="1" (
    echo Opening Student Portal in browser...
    start "" "http://localhost:5501"
    goto MENU
)
if /i "%OPT%"=="2" (
    echo Opening Admin Console in browser...
    start "" "http://localhost:5502"
    goto MENU
)
if /i "%OPT%"=="3" (
    echo Opening Registrar Portal in browser...
    start "" "http://localhost:5503"
    goto MENU
)
if /i "%OPT%"=="4" (
    echo Opening Certificate Verification in browser...
    start "" "http://localhost:5504"
    goto MENU
)
if /i "%OPT%"=="5" (
    echo Opening Main Gateway in browser...
    start "" "http://localhost:5500"
    goto MENU
)
if /i "%OPT%"=="A" (
    echo Opening all portals in separate browser tabs...
    start "" "http://localhost:5500"
    start "" "http://localhost:5501"
    start "" "http://localhost:5502"
    start "" "http://localhost:5503"
    start "" "http://localhost:5504"
    goto MENU
)
if "%OPT%"=="0" (
    goto SHUTDOWN
)
goto MENU

:SHUTDOWN
cls
color 0C
echo ========================================================================
echo  Stopping all ScholarSync backend and portal servers...
echo ========================================================================
powershell -NoProfile -Command "Get-NetTCPConnection -LocalPort 8080, 5500, 5501, 5502, 5503, 5504 -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess -Unique | ForEach-Object { Stop-Process -Id $_ -Force -ErrorAction SilentlyContinue }" >nul 2>&1
echo Done! All services stopped safely.
timeout /t 1 >nul
exit /b 0
