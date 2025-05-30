@echo off
set /p RemotePC="Digite o nome ou IP do computador remoto: "
set /p CaminhoInstalador="Digite o caminho completo do instalador (.msi ou .exe): "

echo Copiando instalador para %RemotePC%...
psexec \\%RemotePC% cmd /c "mkdir C:\Temp"
copy "%CaminhoInstalador%" \\%RemotePC%\C$\Temp\

echo Iniciando instalação remota...
set "NomeInstalador=%CaminhoInstalador:~-12%"
psexec \\%RemotePC% -h -u Administrador -p "SENHA" cmd /c "C:\Temp\%NomeInstalador% /quiet /norestart"

echo Instalação concluída!
pause