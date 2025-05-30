@echo off
set /p RemotePC="Digite o nome ou IP do computador remoto: "
echo Obtendo codigos, nomes e versoes dos produtos instalados em %RemotePC%...
wmic /node:%RemotePC% product get name, identifyingnumber, version
pause