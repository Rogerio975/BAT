@echo off
set /p RemotePC="Digite o nome ou IP do computador remoto: "
echo Obtendo códigos, nomes e versões dos produtos instalados em %RemotePC%...
wmic /node:%RemotePC% product get name, identifyingnumber, version
pause