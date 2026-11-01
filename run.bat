@echo off
setlocal enableextensions
chcp 65001 >nul

REM ============================================================
REM  ai-sandbox :: bootstrap Windows (sin WSL)
REM  Clona el repo y abre VS Code directo desde Windows.
REM
REM  Este .bat es un bootstrap: puede vivir en cualquier lado de
REM  Windows (no necesita el repo clonado de antemano).
REM  Ejecutalo con doble clic o desde cmd/PowerShell:
REM    run.bat [--name <nombre>]
REM ============================================================

REM ---- Config (edita si hace falta) --------------------------
set "TARGET_DIR=ai-sandbox"
set "REPO_URL=https://github.com/bruaguspons/ai-sandbox.git"
REM ------------------------------------------------------------

REM ---- Argumentos: --name <nombre> ----------------------------
REM  Define el directorio y el nombre de la instancia (container +
REM  volumenes de persistencia). Default: ai-sandbox.
:parse_args
if "%~1"=="" goto :args_done
if /i "%~1"=="--name" goto :set_name
if /i "%~1"=="-n" goto :set_name
echo [ERROR] Argumento desconocido: %~1
echo         Uso: %~nx0 [--name ^<nombre^>]
goto :fail
:set_name
if "%~2"=="" (
  echo [ERROR] Falta el valor de %~1.
  goto :fail
)
set "TARGET_DIR=%~2"
shift
shift
goto :parse_args
:args_done

REM  Debe ser un nombre de proyecto Compose valido
echo %TARGET_DIR%| findstr /r /x "[abcdefghijklmnopqrstuvwxyz0123456789][abcdefghijklmnopqrstuvwxyz0123456789_-]*" >nul
if errorlevel 1 (
  echo [ERROR] Nombre invalido: '%TARGET_DIR%'. Usa [a-z0-9_-], empezando con letra o digito.
  goto :fail
)

echo.
echo === ai-sandbox :: setup Windows (sin WSL) ===
echo.

REM ---- 1. git -------------------------------------------------
echo [1/4] Verificando git...
where git >nul 2>&1
if errorlevel 1 (
  echo [ERROR] No se encontro 'git' en el PATH. Instalalo y reintenta.
  echo         https://git-scm.com/download/win
  goto :fail
)
echo       OK.

REM ---- 2. docker ------------------------------------------------
echo [2/4] Verificando docker...
where docker >nul 2>&1
if errorlevel 1 (
  echo [ERROR] No se encontro 'docker' en el PATH. Instala Docker Desktop y reintenta.
  echo         https://www.docker.com/products/docker-desktop/
  goto :fail
)
echo       OK.

REM ---- 3. Clonar el repo en el home de Windows -----------------
echo [3/4] Clonando repo en %%USERPROFILE%%\%TARGET_DIR% ...
if exist "%USERPROFILE%\%TARGET_DIR%" (
  echo       Ya existe, salteando clone.
) else (
  git clone "%REPO_URL%" "%USERPROFILE%\%TARGET_DIR%"
  if errorlevel 1 (
    echo [ERROR] Fallo el git clone.
    goto :fail
  )
  rmdir /s /q "%USERPROFILE%\%TARGET_DIR%\.git"
  echo       .git eliminado ^(proyecto desvinculado del remoto^).
)

REM  Persistir el nombre de la instancia en .env (lo lee docker compose)
set "ENV_FILE=%USERPROFILE%\%TARGET_DIR%\.env"
if not exist "%ENV_FILE%" (
  if exist "%USERPROFILE%\%TARGET_DIR%\.env.example" (
    copy /y "%USERPROFILE%\%TARGET_DIR%\.env.example" "%ENV_FILE%" >nul
  ) else (
    type nul > "%ENV_FILE%"
  )
)
findstr /v /b "SANDBOX_NAME=" "%ENV_FILE%" > "%ENV_FILE%.tmp"
>>"%ENV_FILE%.tmp" echo SANDBOX_NAME=%TARGET_DIR%
move /y "%ENV_FILE%.tmp" "%ENV_FILE%" >nul
echo       Instancia: %TARGET_DIR% ^(SANDBOX_NAME en .env^).

REM ---- 4. Abrir VS Code -----------------------------------------
echo [4/4] Abriendo VS Code...
where code >nul 2>&1
if errorlevel 1 (
  echo [!] No encontre 'code' en el PATH.
  echo     Instala VS Code con la opcion "Add to PATH", o abrilo a mano:
  echo       %USERPROFILE%\%TARGET_DIR%
) else (
  code "%USERPROFILE%\%TARGET_DIR%"
)

echo.
echo Casi listo. Ultimo paso ^(manual, en VS Code^):
echo   Cuando VS Code abra la carpeta, acepta "Reopen in Container".
echo.
goto :done

:fail
echo.
echo Setup interrumpido.
pause
endlocal
exit /b 1

:done
echo Listo.
pause
endlocal
exit /b 0
