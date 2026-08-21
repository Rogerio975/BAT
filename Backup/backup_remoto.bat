@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem Backup remoto de um perfil de usuario usando Robocopy e tar.
set "DESTINO=\\serv\c$\backups"
set "HOST="
set "LOGIN="
set "PERFIL="

set /p "HOST=Hostname do computador remoto: "
if not defined HOST (
    echo Hostname nao informado.
    exit /b 2
)

set /p "LOGIN=Login do usuario (ex.: DOMINIO\usuario): "
if not defined LOGIN (
    echo Login nao informado.
    exit /b 2
)

set /p "PERFIL=Nome da pasta do perfil em C:\Users (ex.: usuario): "
if not defined PERFIL (
    echo Pasta do perfil nao informada.
    exit /b 2
)

for /f "delims=" %%T in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set "STAMP=%%T"
for /f "delims=" %%T in ('powershell -NoProfile -Command "(Get-Date).ToString('yyyy-MM-dd HH:mm:ss')"') do set "INICIO=%%T"
for /f "delims=" %%T in ('powershell -NoProfile -Command "[DateTimeOffset]::Now.ToUnixTimeSeconds()"') do set "INICIO_EPOCH=%%T"

set "ORIGEM=\\%HOST%\c$\Users\%PERFIL%"
set "STAGING=%TEMP%\Backup_%HOST%_%PERFIL%_%STAMP%"
set "ARQUIVO=%DESTINO%\Backup_%HOST%_%PERFIL%_%STAMP%.zip"
set "LOG=%DESTINO%\Backup_%HOST%_%PERFIL%_%STAMP%.log"

if not exist "%DESTINO%\" (
    echo O destino nao esta acessivel: %DESTINO%
    echo Verifique a rede, as permissoes e o compartilhamento administrativo C$.
    exit /b 3
)

>>"%LOG%" echo ============================================================
>>"%LOG%" echo Backup remoto
>>"%LOG%" echo Hostname: %HOST%
>>"%LOG%" echo Login: %LOGIN%
>>"%LOG%" echo Origem: %ORIGEM%
>>"%LOG%" echo Destino: %ARQUIVO%
>>"%LOG%" echo Inicio: %INICIO%

echo Informe a senha de %LOGIN% quando solicitado.
net use "\\%HOST%\c$" /user:"%LOGIN%" *
if errorlevel 1 (
    >>"%LOG%" echo ERRO: Falha na autenticacao em %HOST%.
    echo Falha na autenticacao.
    exit /b 4
)

if not exist "%ORIGEM%\" (
    >>"%LOG%" echo ERRO: A origem nao esta acessivel: %ORIGEM%
    echo A origem nao esta acessivel: %ORIGEM%
    exit /b 4
)

mkdir "%STAGING%" >nul 2>&1
if errorlevel 1 (
    >>"%LOG%" echo ERRO: Nao foi possivel criar a pasta temporaria: %STAGING%
    echo Nao foi possivel criar a pasta temporaria.
    exit /b 5
)

>>"%LOG%" echo.
>>"%LOG%" echo Iniciando Robocopy...
echo Iniciando backup de %ORIGEM%
robocopy "%ORIGEM%" "%STAGING%" /E /ZB /COPY:DAT /DCOPY:DAT /R:2 /W:5 /XJ /FFT /TEE /LOG+:"%LOG%"
set "ROBOCODE=%ERRORLEVEL%"

if %ROBOCODE% GEQ 8 (
    >>"%LOG%" echo ERRO: Robocopy terminou com codigo %ROBOCODE%.
    echo Robocopy falhou com codigo %ROBOCODE%. Consulte o log:
    echo %LOG%
    rmdir /s /q "%STAGING%" >nul 2>&1
    exit /b %ROBOCODE%
)

>>"%LOG%" echo.
>>"%LOG%" echo Compactando arquivos...
echo Compactando arquivos em %ARQUIVO%
tar -a -c -f "%ARQUIVO%" -C "%STAGING%" . >>"%LOG%" 2>&1
set "TARCODE=%ERRORLEVEL%"

if not "%TARCODE%"=="0" (
    >>"%LOG%" echo ERRO: A compactacao terminou com codigo %TARCODE%.
    echo Falha na compactacao. Consulte o log:
    echo %LOG%
    rmdir /s /q "%STAGING%" >nul 2>&1
    exit /b %TARCODE%
)

rmdir /s /q "%STAGING%" >nul 2>&1
for /f "delims=" %%T in ('powershell -NoProfile -Command "(Get-Date).ToString('yyyy-MM-dd HH:mm:ss')"') do set "FIM=%%T"
for /f "delims=" %%T in ('powershell -NoProfile -Command "[DateTimeOffset]::Now.ToUnixTimeSeconds()"') do set "FIM_EPOCH=%%T"
for /f "delims=" %%T in ('powershell -NoProfile -Command "[DateTimeOffset]::Now.ToUnixTimeSeconds() - %INICIO_EPOCH%"') do set "DURACAO=%%T"

>>"%LOG%" echo.
>>"%LOG%" echo Resultado: SUCESSO
>>"%LOG%" echo Codigo Robocopy: %ROBOCODE%
>>"%LOG%" echo Fim: %FIM%
>>"%LOG%" echo Duracao: %DURACAO% segundos
>>"%LOG%" echo ============================================================

echo.
echo Backup concluido com sucesso.
echo Arquivo: %ARQUIVO%
echo Log: %LOG%
echo Duracao: %DURACAO% segundos
exit /b 0
