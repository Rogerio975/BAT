@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Backup Remoto com Robocopy

REM ============================================================
REM  Backup de perfil de usuario em computador remoto (Robocopy)
REM  Origem : \\HOSTNAME\c$\Users\USUARIO
REM  Destino: \\servidor\c$\backups\backup_HOSTNAME
REM  Requer : executar com conta com acesso administrativo
REM           ao computador remoto e ao servidor de destino.
REM ============================================================

REM --- Configuracao: altere o nome do servidor de destino ---
set "SERVIDOR=servidor"
set "RAIZ_BACKUP=\\%SERVIDOR%\c$\backups"

echo ============================================================
echo   BACKUP REMOTO - ROBOCOPY
echo ============================================================
echo.

set /p "HOST=Digite o hostname do computador: "

:novo_usuario
set /p "USUARIO=Digite o nome do usuario: "


REM --- Remove espacos nas pontas (simples) ---
for /f "tokens=* delims= " %%a in ("%HOST%") do set "HOST=%%a"
for /f "tokens=* delims= " %%a in ("%USUARIO%") do set "USUARIO=%%a"

if "%HOST%"=="" (
    echo [ERRO] Hostname nao informado.
    goto :fim_erro
)
if "%USUARIO%"=="" (
    echo [ERRO] Nome de usuario nao informado.
    goto :fim_erro
)

set "ORIGEM=\\%HOST%\c$\Users\%USUARIO%"
set "DESTINO=%RAIZ_BACKUP%\backup_%HOST%"
set "LOGDIR=%DESTINO%\_logs"

echo.
echo Origem : %ORIGEM%
echo Destino: %DESTINO%
echo.

REM --- Testa conectividade com o computador remoto ---
echo Verificando conectividade com %HOST%...
ping -n 2 -w 2000 %HOST% >nul 2>&1
if errorlevel 1 (
    echo [ERRO] Computador %HOST% nao responde ao ping ou nome nao resolvido.
    goto :fim_erro
)

REM --- Verifica acesso a pasta de origem ---
if not exist "%ORIGEM%\" (
    echo [ERRO] Pasta de origem inacessivel ou inexistente:
    echo        %ORIGEM%
    echo        Verifique o usuario, o compartilhamento administrativo C$ e suas permissoes.
    goto :fim_erro
)

REM --- Cria pasta de destino e de logs ---
if not exist "%DESTINO%\" (
    mkdir "%DESTINO%" 2>nul
    if errorlevel 1 (
        echo [ERRO] Nao foi possivel criar a pasta de destino:
        echo        %DESTINO%
        goto :fim_erro
    )
)
if not exist "%LOGDIR%\" mkdir "%LOGDIR%" 2>nul

REM --- Monta nome do log com data e hora (independe de formato regional) ---
for /f "tokens=2 delims==" %%i in ('wmic os get LocalDateTime /value 2^>nul') do set "DT=%%i"
if defined DT (
    set "CARIMBO=!DT:~0,8!_!DT:~8,6!"
) else (
    set "CARIMBO=%RANDOM%"
)
set "LOG=%LOGDIR%\backup_%HOST%_%USUARIO%_%CARIMBO%.log"

echo.
set /p "CONFIRMA=Iniciar o backup? (S/N): "
if /i not "%CONFIRMA%"=="S" (
    echo Operacao cancelada pelo usuario.
    goto :fim
)

echo.
echo Iniciando backup... (log: %LOG%)
echo.

REM ------------------------------------------------------------
REM  Parametros do Robocopy:
REM   /E        copia subpastas, inclusive vazias
REM   /COPY:DAT copia dados, atributos e datas
REM   /DCOPY:DAT preserva dados/atributos/datas das pastas
REM   /R:2 /W:5 2 tentativas, 5s de espera (evita travar em arquivos em uso)
REM   /MT:8     8 threads
REM   /XJ       ignora junction points (evita loops no perfil)
REM   /Z        modo reiniciavel (util em rede)
REM   /FFT      tolerancia de 2s em timestamps
REM   /TEE      exibe no console e grava no log
REM   /NP       sem percentual por arquivo
REM   /XF /XD   exclui arquivos/pastas temporarias e de cache
REM ------------------------------------------------------------
robocopy "%ORIGEM%" "%DESTINO%\%USUARIO%" /E /Z /COPY:DAT /DCOPY:DAT /R:2 /W:5 /MT:8 /XJ /FFT /TEE /NP /UNILOG+:"%LOG%" ^
    /XF "NTUSER.DAT*" "ntuser.ini" "*.tmp" "Thumbs.db" "desktop.ini" "UsrClass.dat*" ^
    /XD "%ORIGEM%\AppData\Local\Temp" ^
        "%ORIGEM%\AppData\Local\Microsoft\Windows\INetCache" ^
        "%ORIGEM%\AppData\Local\Microsoft\Windows\WebCache" ^
        "%ORIGEM%\AppData\Local\Google\Chrome\User Data\Default\Cache" ^
        "%ORIGEM%\AppData\Local\Microsoft\Edge\User Data\Default\Cache" ^
        "%ORIGEM%\AppData\Local\Packages" ^
        "%ORIGEM%\AppData\Local\Application Data" ^
        "%ORIGEM%\$RECYCLE.BIN"

set "RC=%ERRORLEVEL%"

echo.
echo ============================================================
REM --- Codigos de saida do Robocopy: 0-7 = sucesso (com ou sem copias); >=8 = falha ---
if %RC% GEQ 16 (
    echo [ERRO GRAVE] Robocopy falhou - codigo %RC% ^(erro fatal ou parametros invalidos^).
    goto :fim_erro_log
)
if %RC% GEQ 8 (
    echo [ATENCAO] Backup concluido com ERROS - codigo %RC% ^(alguns arquivos nao foram copiados^).
    goto :fim_erro_log
)
if %RC% EQU 0 echo [OK] Nenhum arquivo novo ou alterado. Origem e destino ja estao sincronizados.
if %RC% EQU 1 echo [OK] Backup concluido. Arquivos copiados com sucesso.
if %RC% EQU 2 echo [OK] Backup concluido. Existem arquivos extras no destino.
if %RC% EQU 3 echo [OK] Backup concluido. Arquivos copiados e extras detectados no destino.
if %RC% GEQ 4 if %RC% LEQ 7 echo [OK] Backup concluido com diferencas/incompatibilidades menores - codigo %RC%.
echo Log: %LOG%
echo ============================================================
echo.
set /p "MAIS_USUARIOS=Ha mais usuarios para copiar? (S/N): "
if /i "%MAIS_USUARIOS%"=="S" goto :novo_usuario
goto :fim

:fim_erro_log
echo Consulte o log: %LOG%
echo ============================================================
echo.
pause
endlocal
exit /b %RC%

:fim_erro
echo.
pause
endlocal
exit /b 1

:fim
echo.
pause
endlocal
exit /b 0
