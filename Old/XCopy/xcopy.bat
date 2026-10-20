@echo off
setlocal

set /p "REMOTE_PC=Digite o nome do computador de origem: "
if "%REMOTE_PC%"=="" echo Erro: Nome do computador nao fornecido. & exit /b 1 \\ Verifica se o nome do computador foi fornecido, se nao, exibe a mensagem de erro e sai com codigo de erro 1.
if "%~1"=="" goto usage \\ Verifica se o primeiro argumento (origem) foi fornecido, se nao, exibe a mensagem de uso e sai com codigo de erro 1.
if "%~2"=="" goto usage \\ Verifica se o segundo argumento (destino) foi fornecido, se nao, exibe a mensagem de uso e sai com codigo de erro 1.

set "SOURCE=\\%REMOTE_PC%\%~1"
set "DEST=%~2" \\ Define as variaveis de ambiente SOURCE e DEST com os valores fornecidos pelo usuario, formatando a origem como um caminho de rede.

echo Copiando de "%SOURCE%" para "%DEST%"...
:: Executa a copia de arquivos e subpastas (/E), tratando o destino como pasta (/I), incluindo ocultos (/H) e sem pedir confirmacao (/Y)
xcopy.exe "%SOURCE%" "%DEST%" /E /I /H /Y \\ Verifica o codigo de erro retornado pelo comando xcopy. Se for maior ou igual a 1, exibe a mensagem de falha e sai com o codigo de erro. Caso contrario, exibe a mensagem de sucesso.
if errorlevel 1 (
    echo Falha ao copiar.
    exit /b %errorlevel%
) else (
    echo Copia concluida com sucesso.
)
exit /b 0

:usage
echo Uso: %~nx0 "origem" "destino"
echo Copia arquivos e diretorios, incluindo subdiretorios, utilizando XCopy.
exit /b 1
