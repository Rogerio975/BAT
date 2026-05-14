@echo off
setlocal

:: Pasta dos logs
set LOGDIR=C:\Scripts\Logs

:: Cria pasta se nao existir
if not exist "%LOGDIR%" (
    mkdir "%LOGDIR%"
)

:: Data e hora para o nome do log
for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd_HH-mm-ss"') do set DATETIME=%%i

:: Arquivo de log
set LOGFILE=%LOGDIR%\winget_upgrade_%DATETIME%.txt

:: Inicio do log
echo ========================================== >> "%LOGFILE%"
echo Inicio da atualizacao: %date% %time% >> "%LOGFILE%"
echo ========================================== >> "%LOGFILE%"
echo. >> "%LOGFILE%"

:: Atualizacao silenciosa
winget upgrade --all ^
--silent ^
--include-unknown ^
--disable-interactivity ^
--accept-source-agreements ^
--accept-package-agreements >> "%LOGFILE%" 2>&1

:: Final do log
echo. >> "%LOGFILE%"
echo ========================================== >> "%LOGFILE%"
echo Fim da atualizacao: %date% %time% >> "%LOGFILE%"
echo ========================================== >> "%LOGFILE%"

endlocal
exit