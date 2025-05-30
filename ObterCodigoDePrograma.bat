@echo off
set /p RemotePC="Digite o nome ou IP do computador remoto: "
echo Obtendo codigos de produto instalados em %RemotePC%...
wmic /node:%RemotePC% product get name, identifyingnumber
pause