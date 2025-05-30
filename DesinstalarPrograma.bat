@echo off
set /p RemotePC="Digite o nome ou IP do computador remoto: "
set /p ProductCode="Digite o código de identificação do produto: "

echo Conectando a %RemotePC% e desinstalando o produto com código %ProductCode%...
psexec \\%RemotePC% cmd /c "wmic product where identifyingnumber='%ProductCode%' call uninstall /nointeractive"

echo Processo concluído!
pause
