@echo off
setlocal enableextensions
chcp 65001 >nul

REM ============================================================
REM  ai-sandbox :: bootstrap WSL2
REM  Clona el repo DENTRO del filesystem de Linux (ext4) y abre
REM  VS Code conectado a WSL, para evitar el mount 9p (lento).
REM
REM  Este .bat es un bootstrap: puede vivir en cualquier lado de
REM  Windows (no necesita el repo clonado de antemano).
REM  Ejecutalo con doble clic o desde cmd/PowerShell:
REM    run-wsl.bat [--name <nombre>] [--agents <lista>]
REM ============================================================

REM ---- Config (edita si hace falta) --------------------------
set "DISTRO=Ubuntu"
set "TARGET_DIR=ai-sandbox"
set "AGENTS="
set "AGENTS_SET="
set "REPO_URL=https://github.com/bruaguspons/ai-sandbox.git"
REM  Podes hardcodear la URL arriba; si la dejas vacia, te la pide.
REM ------------------------------------------------------------

REM ---- Argumentos: --name <nombre> --agents <lista> ------------
REM  --name define el directorio y el nombre de la instancia
REM  (container + volumenes de persistencia). Default: ai-sandbox.
REM  --agents define los agentes a instalar, separados por coma
REM  (ej: claude,codex,opencode). Se escribe como AGENTS en .env;
REM  sin --agents se respeta lo que ya tenga el .env.
:parse_args
if "%~1"=="" goto :args_done
if /i "%~1"=="--name" goto :set_name
if /i "%~1"=="-n" goto :set_name
if /i "%~1"=="--agents" goto :set_agents
if /i "%~1"=="-a" goto :set_agents
echo [ERROR] Argumento desconocido: %~1
echo         Uso: %~nx0 [--name ^<nombre^>] [--agents ^<lista^>]
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
:set_agents
set "_ARG=%~2"
if "%_ARG%"=="" (
  echo [ERROR] Falta el valor de %~1.
  goto :fail
)
if "%_ARG:~0,1%"=="-" (
  echo [ERROR] Falta el valor de %~1.
  goto :fail
)
set "AGENTS=%_ARG%"
set "AGENTS_SET=1"
shift
shift
REM  cmd separa argumentos por coma: "claude,codex" llega como dos
REM  tokens. Se juntan los siguientes hasta el proximo flag.
:more_agents
set "_ARG=%~1"
if "%_ARG%"=="" goto :parse_args
if "%_ARG:~0,1%"=="-" goto :parse_args
set "AGENTS=%AGENTS%,%_ARG%"
shift
goto :more_agents
:args_done

REM  Debe ser un nombre de proyecto Compose valido
echo %TARGET_DIR%| findstr /r /x "[abcdefghijklmnopqrstuvwxyz0123456789][abcdefghijklmnopqrstuvwxyz0123456789_-]*" >nul
if errorlevel 1 (
  echo [ERROR] Nombre invalido: '%TARGET_DIR%'. Usa [a-z0-9_-], empezando con letra o digito.
  goto :fail
)

REM  Lista de agentes: nombres [a-z0-9-] separados por coma
if defined AGENTS_SET (
  echo %AGENTS%| findstr /r /x "[abcdefghijklmnopqrstuvwxyz0123456789-][abcdefghijklmnopqrstuvwxyz0123456789,-]*" >nul
  if errorlevel 1 goto :bad_agents
  if "%AGENTS:~-1%"=="," goto :bad_agents
  if not "%AGENTS:,,=%"=="%AGENTS%" goto :bad_agents
)

echo.
echo === ai-sandbox :: setup WSL2 ===
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

REM  Persistir el nombre de la instancia en .env (lo lee docker compose)
wsl -d %DISTRO% -- bash -lc "cd ~/'%TARGET_DIR%' && { [ -f .env ] || cp .env.example .env 2>/dev/null || : > .env; } && { grep -v '^SANDBOX_NAME=' .env; echo 'SANDBOX_NAME=%TARGET_DIR%'; } > .env.tmp && mv .env.tmp .env"
if errorlevel 1 (
  echo [ERROR] No se pudo escribir SANDBOX_NAME en .env.
  goto :fail
)
echo       Instancia: %TARGET_DIR% ^(SANDBOX_NAME en .env^).

REM  Persistir los agentes en .env (build arg AGENTS de docker compose)
if not defined AGENTS_SET goto :agents_done
wsl -d %DISTRO% -- bash -lc "cd ~/'%TARGET_DIR%' && { grep -v '^AGENTS=' .env; echo 'AGENTS=%AGENTS%'; } > .env.tmp && mv .env.tmp .env"
if errorlevel 1 (
  echo [ERROR] No se pudo escribir AGENTS en .env.
  goto :fail
)
echo       Agentes: %AGENTS% ^(AGENTS en .env^).
:agents_done

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
echo      Si el container ya existia y cambiaste --agents, usa "Rebuild Container".
echo   2^) Ya dentro del container, verifica que NO estas sobre 9p:
echo        findmnt -T /workspaces -o TARGET,SOURCE,FSTYPE
echo      El FSTYPE no debe decir 9p.
echo.
goto :done

:bad_agents
echo [ERROR] Agentes invalidos: '%AGENTS%'. Usa nombres [a-z0-9-] separados por coma ^(ej: claude,codex^).
goto :fail

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