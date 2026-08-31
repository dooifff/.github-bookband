@echo off
setlocal enabledelayedexpansion

REM ============================================
REM StudioBook - Midtrans Sandbox Setup (Windows)
REM ============================================

echo.
echo ============================================
echo    StudioBook - Midtrans Sandbox Setup
echo ============================================
echo.

set "ENV_FILE=backend\.env"

REM Cek file .env
if not exist "%ENV_FILE%" (
    echo Error: File %ENV_FILE% tidak ditemukan!
    echo Jalankan script ini dari root project.
    pause
    exit /b 1
)

echo Langkah 1: Daftar akun Midtrans Sandbox
echo.
echo   1. Buka https://account.sandbox.midtrans.com/register
echo   2. Isi data diri dan daftar
echo   3. Setelah daftar, login ke Dashboard
echo   4. Buka menu 'Settings' ^> 'Access Keys'
echo   5. Copy 'Client Key' dan 'Server Key'
echo.

echo Langkah 2: Masukkan Access Keys
echo.

set /p CLIENT_KEY="  Client Key (SB-Mid-client-xxxx): "
set /p SERVER_KEY="  Server Key (SB-Mid-server-xxxx): "
set /p MERCHANT_ID="  Merchant ID (optional, tekan Enter untuk skip): "

if "%CLIENT_KEY%"=="" (
    echo.
    echo Error: Client Key wajib diisi!
    pause
    exit /b 1
)

if "%SERVER_KEY%"=="" (
    echo.
    echo Error: Server Key wajib diisi!
    pause
    exit /b 1
)

echo.
echo Langkah 3: Update file .env
echo.

REM Backup
copy "%ENV_FILE%" "%ENV_FILE%.backup" >nul
echo   [OK] Backup .env -^> .env.backup

REM Update MIDTRANS keys menggunakan PowerShell
powershell -Command "(Get-Content '%ENV_FILE%') -replace '^MIDTRANS_CLIENT_KEY=.*', 'MIDTRANS_CLIENT_KEY=%CLIENT_KEY%' | Set-Content '%ENV_FILE%'"
echo   [OK] MIDTRANS_CLIENT_KEY updated

powershell -Command "(Get-Content '%ENV_FILE%') -replace '^MIDTRANS_SERVER_KEY=.*', 'MIDTRANS_SERVER_KEY=%SERVER_KEY%' | Set-Content '%ENV_FILE%'"
echo   [OK] MIDTRANS_SERVER_KEY updated

if not "%MERCHANT_ID%"=="" (
    powershell -Command "(Get-Content '%ENV_FILE%') -replace '^MIDTRANS_MERCHANT_ID=.*', 'MIDTRANS_MERCHANT_ID=%MERCHANT_ID%' | Set-Content '%ENV_FILE%'"
    echo   [OK] MIDTRANS_MERCHANT_ID updated
)

powershell -Command "(Get-Content '%ENV_FILE%') -replace '^MIDTRANS_IS_PRODUCTION=.*', 'MIDTRANS_IS_PRODUCTION=false' | Set-Content '%ENV_FILE%'"
echo   [OK] MIDTRANS_IS_PRODUCTION=false (sandbox mode)

REM Update webhook URL
for /f "tokens=2 delims==" %%a in ('findstr "APP_URL=" %ENV_FILE%') do set APP_URL=%%a
set "WEBHOOK_URL=%APP_URL%/api/v1/payments/webhook/midtrans"

powershell -Command "(Get-Content '%ENV_FILE%') -replace '^MIDTRANS_WEBHOOK_URL=.*', 'MIDTRANS_WEBHOOK_URL=%WEBHOOK_URL%' | Set-Content '%ENV_FILE%'"
echo   [OK] MIDTRANS_WEBHOOK_URL = %WEBHOOK_URL%

REM Update web/.env
set "VITE_ENV_FILE=web\.env"

if exist "%VITE_ENV_FILE%" (
    powershell -Command "(Get-Content '%VITE_ENV_FILE%') -replace '^VITE_MIDTRANS_SNAP_URL=.*', 'VITE_MIDTRANS_SNAP_URL=https://app.sandbox.midtrans.com/snap/snap.js' | Set-Content '%VITE_ENV_FILE%'"
    powershell -Command "(Get-Content '%VITE_ENV_FILE%') -replace '^VITE_MIDTRANS_CLIENT_KEY=.*', 'VITE_MIDTRANS_CLIENT_KEY=%CLIENT_KEY%' | Set-Content '%VITE_ENV_FILE%'"
) else (
    echo VITE_MIDTRANS_SNAP_URL=https://app.sandbox.midtrans.com/snap/snap.js> "%VITE_ENV_FILE%"
    echo VITE_MIDTRANS_CLIENT_KEY=%CLIENT_KEY%>> "%VITE_ENV_FILE%"
)
echo   [OK] web/.env updated (VITE Midtrans keys)

echo.
echo ============================================
echo    Setup Midtrans Sandbox Selesai!
echo ============================================
echo.
echo   Webhook URL untuk Midtrans Dashboard:
echo   %WEBHOOK_URL%
echo.
echo   Cara Testing:
echo   ----------------------------------------
echo   Kartu Kredit (Berhasil):
echo     Nomor    : 4811 1111 1111 1114
echo     CVV      : 123
echo     Expired  : 12/25
echo.
echo   Kartu Kredit (Gagal):
echo     Nomor    : 4811 1111 1111 1118
echo     CVV      : 123
echo     Expired  : 12/25
echo.
echo   GoPay (Berhasil):
echo     Phone    : 081111111111
echo     OTP      : 123456
echo.
echo   BCA VA (Berhasil):
echo     Nomor VA : 1234567890
echo.
echo   Restart backend:  cd backend ^& php artisan serve
echo   Restart frontend: cd web ^& npm run dev
echo.
pause
