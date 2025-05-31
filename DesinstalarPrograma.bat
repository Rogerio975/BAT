@echo off
set /p RemotePC="Digite o nome ou IP do computador remoto: "
set /p ProductCode="Digite o código de identificação do produto: "

echo Conectando a %RemotePC% e desinstalando o produto com código %ProductCode%...
{6C0A3C5E-7725-49D8-A016-B3ADCACF61C2}psexec \\%RemotePC% cmd /c wmic product where identifyingnumber^='%ProductCode%' call uninstall /nointeractive

echo Processo concluído!
pause
