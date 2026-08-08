@echo off
setlocal enableextensions
chcp 65001 >nul

REM ============================================================
REM  claude-docker :: bootstrap WSL2
REM  Clona el repo DENTRO del filesystem de Linux (ext4) y abre
REM  VS Code conectado a WSL, para evitar el mount 9p (lento).
REM
REM  Este .bat es un bootstrap: puede vivir en cualquier lado de
REM  Windows (no necesita el repo clonado de antemano).
REM  Ejecutalo con doble clic o desde cmd/PowerShell.
REM ============================================================

REM ---- Config (edita si hace falta) --------------------------
set "DISTRO=Ubuntu"
set "TARGET_DIR=claude-docker"
set "REPO_URL=https://github.com/bruaguspons/claude-docker.git"
REM  Podes hardcodear la URL arriba; si la dejas vacia, te la pide.
REM ------------------------------------------------------------

echo.
echo === claude-docker :: setup WSL2 ===
echo.

REM ---- 1. Verificar que WSL existe ---------------------------
where wsl >nul 2>&1
if errorlevel 1 (
  echo [ERROR] No se encontro 'wsl'. Habilita WSL2 en Windows y reintenta.
  echo         En PowerShell como admin:  wsl --install
  goto :fail
)

REM ---- 2. Verificar / instalar la distro --------------------
echo [1/6] Verificando distro "%DISTRO%"...
wsl -d %DISTRO% -- true 2>nul
if errorlevel 1 (
  echo       Distro no encontrada. Instalando "%DISTRO%"...
  wsl --install -d %DISTRO%
  echo.
  echo [!] Puede que necesites REINICIAR y completar el setup inicial de
  echo     %DISTRO% ^(usuario y contrasena^). Despues volve a correr este .bat.
  goto :done
)
echo       OK.

REM ---- 3. git dentro de WSL ---------------------------------
echo [2/6] Verificando git en %DISTRO%...
wsl -d %DISTRO% -- bash -lc "command -v git >/dev/null 2>&1"
if errorlevel 1 (
  echo       git no esta instalado. Instalando ^(puede pedir tu contrasena de sudo^)...
  wsl -d %DISTRO% -- bash -lc "sudo apt-get update && sudo apt-get install -y git"
  if errorlevel 1 (
    echo [ERROR] No se pudo instalar git.
    goto :fail
  )
)
echo       OK.

REM ---- 4. docker dentro de WSL (Docker Desktop integration) -
echo [3/6] Verificando docker en %DISTRO%...
wsl -d %DISTRO% -- bash -lc "command -v docker >/dev/null 2>&1"
if errorlevel 1 (
  echo.
  echo [!] 'docker' no esta disponible dentro de %DISTRO%.
  echo     Abri Docker Desktop y habilita:
  echo       Settings ^> Resources ^> WSL Integration ^> toggle de %DISTRO%
  echo     Dejalo corriendo y presiona una tecla para continuar...
  pause >nul
)
echo       OK.

REM ---- 5. Clonar el repo en el home de WSL (ext4) y borrar .git
echo [4/6] Clonando repo en ~/%TARGET_DIR% ...
wsl -d %DISTRO% -- bash -lc "cd ~ && if [ -d '%TARGET_DIR%' ]; then echo '      Ya existe, salteando clone.'; else git clone '%REPO_URL%' '%TARGET_DIR%' && rm -rf '%TARGET_DIR%/.git' && echo '      .git eliminado (proyecto desvinculado del remoto).'; fi"
if errorlevel 1 (
  echo [ERROR] Fallo el git clone.
  goto :fail
)

REM ---- 6. Resolver HOME de WSL y abrir VS Code --------------
echo [5/6] Abriendo VS Code conectado a WSL...
set "WSL_HOME="
for /f "usebackq tokens=* delims=" %%i in (`wsl -d %DISTRO% -- bash -c "echo $HOME"`) do set "WSL_HOME=%%i"
if "%WSL_HOME%"=="" (
  echo [ERROR] No pude resolver el HOME de WSL.
  goto :fail
)

where code >nul 2>&1
if errorlevel 1 (
  echo [!] No encontre 'code' en el PATH de Windows.
  echo     Instala VS Code con la opcion "Add to PATH", o abrilo a mano:
  echo       Remote-WSL ^> Open Folder ^> %WSL_HOME%/%TARGET_DIR%
) else (
  code --remote wsl+%DISTRO% "%WSL_HOME%/%TARGET_DIR%"
)

echo.
echo [6/6] Casi listo. Ultimos pasos ^(manuales, en VS Code^):
echo   1^) Cuando VS Code abra la carpeta, aceptá "Reopen in Container".
echo   2^) Ya dentro del container, verifica que NO estas sobre 9p:
echo        findmnt -T /workspaces -o TARGET,SOURCE,FSTYPE
echo      El FSTYPE no debe decir 9p.
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