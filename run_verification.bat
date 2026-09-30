@echo off
REM Runs sql\RUN_ALL_PROJECT_DEMO.sql against local SQL Server (Windows authentication).
color 0A
title Job Postings Market Analytics - Verification Test
echo ========================================================================
echo   JOB POSTINGS MARKET ANALYTICS - FULL SYSTEM VERIFICATION
echo ========================================================================
echo.
echo Connecting to SQL Server (localhost)...
echo Running sql\RUN_ALL_PROJECT_DEMO.sql...
echo.
sqlcmd -S localhost -E -C -i "%~dp0sql\RUN_ALL_PROJECT_DEMO.sql"
echo.
echo ========================================================================
echo   TEST COMPLETED! Press any key to exit.
echo ========================================================================
pause >nul
