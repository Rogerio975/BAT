@echo off
rem ============================================================================
rem  Aplicar-Win11.cmd
rem  Particiona o disco (UEFI/GPT), aplica o win11.wim, injeta drivers (opcional),
rem  grava o unattend.xml com o nome do computador e cria o boot.
rem  Execute a partir do WinPE em modo UEFI.
rem
rem  Estrutura esperada (pendrive, disco externo ou compartilhamento):
rem     ?:\Images\win11.wim
rem     ?:\Images\unattend.xml     (ou na mesma pasta deste script)
rem     ?:\Images\Drivers\...      (opcional, injetado com /Recurse)
rem
rem  Uso:  Aplicar-Win11.cmd [caminho_do_wim]
rem ============================================================================
setlocal EnableExtensions EnableDelayedExpansion
title Aplicar imagem Windows 11

rem ======================== CONFIGURACAO ========================
set "WIM_NAME=win11.wim"
set "WIM_INDEX=1"
set "TARGET_DISK=0"
rem Opcional: compartilhamento de rede que contem a pasta Images (ex.: \\servidor\implantacao)
set "IMAGE_SHARE="
set "SHARE_USER="
rem ==============================================================

if not defined TEMP set "TEMP=X:\"

echo.
echo ==================================================
echo   APLICACAO DE IMAGEM WINDOWS 11 (UEFI / GPT)
echo ==================================================
echo.

rem --- 1. Exige boot em UEFI ---
wpeutil UpdateBootInfo >nul 2>&1
set "FW="
for /f "tokens=3" %%A in ('reg query HKLM\System\CurrentControlSet\Control /v PEFirmwareType 2^>nul ^| findstr /i "PEFirmwareType"') do set "FW=%%A"
if /i not "!FW!"=="0x2" (
    echo [ERRO] O boot em modo UEFI e obrigatorio. Ajuste a BIOS e inicie o WinPE em UEFI.
    goto :fail
)

rem --- 2. Letras de unidade que o script vai usar ---
if exist S:\ (
    echo [ERRO] A unidade S: ja esta em uso. Remova ou reatribua antes de continuar.
    goto :fail
)
if exist W:\ (
    echo [ERRO] A unidade W: ja esta em uso. Remova ou reatribua antes de continuar.
    goto :fail
)

rem --- 3. Compartilhamento de rede (opcional) ---
if not defined IMAGE_SHARE goto :findwim
echo Conectando em %IMAGE_SHARE% ...
if defined SHARE_USER (
    net use Z: "%IMAGE_SHARE%" /user:%SHARE_USER% *
) else (
    net use Z: "%IMAGE_SHARE%"
)
if errorlevel 1 (
    echo [ERRO] Falha ao conectar no compartilhamento.
    goto :fail
)

rem --- 4. Localiza o .wim ---
:findwim
set "WIM="
if not "%~1"=="" if exist "%~1" set "WIM=%~1"
if not defined WIM (
    for %%D in (Z Y V U T R Q P O N M L K J I H G F E D C) do (
        if not defined WIM if exist "%%D:\Images\%WIM_NAME%" set "WIM=%%D:\Images\%WIM_NAME%"
    )
)
if not defined WIM (
    echo [ERRO] %WIM_NAME% nao encontrado em ?:\Images\
    goto :fail
)
for %%F in ("!WIM!") do set "WIMDIR=%%~dpF"
echo Imagem localizada: !WIM!
echo.
dism /Get-WimInfo /WimFile:"!WIM!"
set "IDX="
set /p "IDX=Indice da imagem [%WIM_INDEX%]: "
if defined IDX set "WIM_INDEX=!IDX!"

rem --- 5. Disco de destino ---
echo.
> "%TEMP%\dp-list.txt" echo list disk
diskpart /s "%TEMP%\dp-list.txt"
set "DSK="
set /p "DSK=Disco de destino [%TARGET_DISK%]: "
if defined DSK (
    for /f "delims=0123456789" %%X in ("!DSK!") do (
        echo [ERRO] Informe apenas o numero do disco.
        goto :fail
    )
    set "TARGET_DISK=!DSK!"
)

rem --- 6. Nome do computador ---
:askname
set "PCNAME="
set /p "PCNAME=Nome do computador (ate 15 caracteres): "
if not defined PCNAME goto :askname
if not "!PCNAME:~15!"=="" (
    echo Nome muito longo. O limite e 15 caracteres.
    goto :askname
)
echo(!PCNAME!| findstr /r /x "[A-Za-z0-9-][A-Za-z0-9-]*" >nul || (
    echo Use apenas letras, numeros e hifen.
    goto :askname
)

rem --- 7. Confirmacao ---
echo.
echo --------------------------------------------------
echo  Imagem : !WIM!  (indice !WIM_INDEX!)
echo  Disco  : !TARGET_DISK!
echo  Nome   : !PCNAME!
echo --------------------------------------------------
echo  ATENCAO: TODOS OS DADOS DO DISCO !TARGET_DISK! SERAO APAGADOS.
echo.
set "CONF="
set /p "CONF=Digite APAGAR para continuar: "
if /i not "!CONF!"=="APAGAR" goto :cancel

rem --- 8. Particionamento (EFI 300 MB + MSR 16 MB + Windows) ---
(
    echo select disk !TARGET_DISK!
    echo clean
    echo convert gpt
    echo create partition efi size=300
    echo format quick fs=fat32 label="System"
    echo assign letter=S
    echo create partition msr size=16
    echo create partition primary
    echo format quick fs=ntfs label="Windows"
    echo assign letter=W
    echo exit
) > "%TEMP%\dp-layout.txt"

echo.
echo [1/5] Particionando o disco !TARGET_DISK! ...
diskpart /s "%TEMP%\dp-layout.txt"
if errorlevel 1 (
    echo [ERRO] Falha no diskpart.
    goto :fail
)
if not exist W:\ (
    echo [ERRO] Particao W: nao foi criada.
    goto :fail
)

rem --- 9. Aplica a imagem ---
echo.
echo [2/5] Aplicando a imagem (pode demorar) ...
mkdir W:\_scratch >nul 2>&1
dism /Apply-Image /ImageFile:"!WIM!" /Index:!WIM_INDEX! /ApplyDir:W:\ /ScratchDir:W:\_scratch /Verify
if errorlevel 1 (
    echo [ERRO] Falha ao aplicar a imagem. Veja X:\Windows\Logs\DISM\dism.log
    goto :fail
)

rem --- 10. Drivers (opcional) ---
echo.
echo [3/5] Drivers ...
if exist "!WIMDIR!Drivers\" (
    dism /Image:W:\ /Add-Driver /Driver:"!WIMDIR!Drivers" /Recurse /ScratchDir:W:\_scratch
    if errorlevel 1 echo [AVISO] Alguns drivers nao foram injetados. Veja o log do DISM.
) else (
    echo Pasta Drivers nao encontrada. Etapa ignorada.
)

rem --- 11. Arquivo de resposta com o nome do computador ---
echo.
echo [4/5] Gravando unattend.xml ...
set "TPL="
if exist "!WIMDIR!unattend.xml" set "TPL=!WIMDIR!unattend.xml"
if not defined TPL if exist "%~dp0unattend.xml" set "TPL=%~dp0unattend.xml"

if not defined TPL (
    echo [AVISO] unattend.xml nao encontrado. O PC iniciara no OOBE padrao, sem ingresso no dominio.
) else (
    set "OUT=W:\Windows\Panther\Unattend\Unattend.xml"
    mkdir W:\Windows\Panther\Unattend >nul 2>&1
    if exist "!OUT!" del /f /q "!OUT!"
    for /f "usebackq delims=" %%L in (`findstr /n "^" "!TPL!"`) do (
        set "LINE=%%L"
        set "LINE=!LINE:*:=!"
        set "LINE=!LINE:@@COMPUTERNAME@@=%PCNAME%!"
        >>"!OUT!" echo(!LINE!
    )
    if not exist "!OUT!" (
        echo [ERRO] Falha ao gravar o unattend.xml.
        goto :fail
    )
    echo Gravado em !OUT!
)

rem --- 12. Boot UEFI ---
echo.
echo [5/5] Criando o boot ...
bcdboot W:\Windows /s S: /f UEFI
if errorlevel 1 (
    echo [ERRO] Falha no bcdboot.
    goto :fail
)

rem --- 13. Limpeza e log ---
copy /y X:\Windows\Logs\DISM\dism.log W:\Windows\Temp\implantacao-dism.log >nul 2>&1
rmdir /s /q W:\_scratch >nul 2>&1

echo.
echo ==================================================
echo   Concluido. Remova o pendrive e reinicie.
echo   O PC fara a configuracao inicial e ingressara
echo   no dominio automaticamente (cabo de rede conectado).
echo ==================================================
pause
wpeutil reboot
exit /b 0

:cancel
echo.
echo Operacao cancelada. Nenhuma alteracao foi feita.
pause
exit /b 1

:fail
echo.
echo Operacao interrompida.
pause
exit /b 1
