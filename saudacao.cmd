@echo off

:inicio
cls
echo Ola Galera!

rem Aguarda 30 segundos. O parâmetro /nobreak impede que uma tecla interrompa a espera, e >nul oculta a mensagem do contador.
timeout /t 30 /nobreak >nul

cls

rem Aguarda 90 segundos. Não permite interrupção por tecla e oculta a contagem.
timeout /t 90 /nobreak >nul
goto inicio
