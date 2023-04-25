@echo off
setlocal enableextensions

:: Definindo as variáveis
set cmdFile=%~nx0
set ps1File=%cmdFile:.bat=.ps1%
set ps1FileLog=%ps1File:.ps1=.log%

:: Criando o diretório de logs, se não existir
if not exist "..\ps\log" mkdir ..\ps\log

:: Executando o script PowerShell e redirecionando a saída para o arquivo de log
powerShell -executionPolicy bypass -file "..\ps\lib\totvsGetDataModelPeriod.ps1" %ps1File% 1> "..\ps\log\%ps1FileLog%" 2>&1

:: Listando o arquivo de log gerado
dir ..\ps\log\%ps1FileLog%

:: Verificando se há erros no arquivo de log
set /p hasError=<..\ps\log\%ps1FileLog%

:: Se houver erros, imprime o erro, aguarda uma hora e reinicia o script
if [%hasError%] NEQ [] (
  @echo on
  echo %hasError%
  timeout /T 3600 /NOBREAK > NUL
  start /b %cmdFile%
)
