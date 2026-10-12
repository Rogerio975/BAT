@echo off
rem ============================================================================
rem  Capturar-Win11.cmd
rem  Captura o Windows do PC de referencia (ja generalizado com Sysprep) em um
rem  arquivo .wim. Execute a partir do WinPE.
rem
rem  Uso:  Capturar-Win11.cmd [caminho_do_wim]
rem  Ex.:  Capturar-Win11.cmd D:\Images\win11.wim
rem ============================================================================
setlocal EnableExtensions EnableDelayedExpansion
title Capturar imagem Windows 11

echo.
echo ==================================================
echo   CAPTURA DE IMAGEM WINDOWS 11 (WinPE)
echo   Execute somente apos Sysprep /generalize /shutdown
echo ==================================================
echo.

rem --- 1. Localiza a unidade do Windows instalado (ignora X: do WinPE) ---
set "WINDRV="
for %%D in (C D E F G H I J K L M N O P Q R S T U V W Y Z) do (
    if not defined WINDRV if exist "%%D:\Windows\System32\Config\SYSTEM" set "WINDRV=%%D:"
)
if not defined WINDRV (
    echo [ERRO] Nenhuma instalacao do Windows encontrada.
    goto :fail
)
echo Windows encontrado em: !WINDRV!\

rem --- 2. Confere se o Sysprep foi concluido ---
if not exist "!WINDRV!\Windows\System32\Sysprep\Sysprep_succeeded.tag" (
    echo.
    echo [ATENCAO] Sysprep_succeeded.tag nao encontrado.
    echo Esta instalacao pode NAO estar generalizada.
    set /p "GO=Continuar mesmo assim? Digite SIM: "
    if /i not "!GO!"=="SIM" goto :cancel
)

rem --- 3. Destino do .wim ---
set "OUT=%~1"
if not defined OUT set /p "OUT=Caminho de destino do .wim (ex.: D:\Images\win11.wim): "
if not defined OUT goto :fail

set "OUTDRV=!OUT:~0,2!"
if /i "!OUTDRV!"=="!WINDRV!" (
    echo [ERRO] O destino nao pode estar no disco que sera capturado.
    goto :fail
)

for %%F in ("!OUT!") do if not exist "%%~dpF" mkdir "%%~dpF"

if exist "!OUT!" (
    set /p "OW=O arquivo ja existe. Sobrescrever? Digite SIM: "
    if /i not "!OW!"=="SIM" goto :cancel
    del /f /q "!OUT!"
)

rem --- 4. Nome da imagem ---
set "IMGNAME="
set /p "IMGNAME=Nome da imagem [Windows 11 Base]: "
if not defined IMGNAME set "IMGNAME=Windows 11 Base"

echo.
echo Origem : !WINDRV!\
echo Destino: !OUT!
echo Nome   : !IMGNAME!
echo.

rem --- 5. Captura ---
dism /Capture-Image /ImageFile:"!OUT!" /CaptureDir:!WINDRV!\ /Name:"!IMGNAME!" /Description:"Capturada em %DATE%" /Compress:max /Verify
if errorlevel 1 (
    echo.
    echo [ERRO] Falha na captura. Veja X:\Windows\Logs\DISM\dism.log
    goto :fail
)

echo.
echo ==================================================
echo   Captura concluida: !OUT!
echo   NAO inicie o Windows de referencia novamente
echo   antes de guardar a imagem.
echo ==================================================
pause
exit /b 0

:cancel
echo Operacao cancelada.
pause
exit /b 1

:fail
echo.
echo Operacao interrompida.
pause
exit /b 1
