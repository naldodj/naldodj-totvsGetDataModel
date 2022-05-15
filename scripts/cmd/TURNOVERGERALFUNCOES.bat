@echo off 
setlocal enableextensions 
set cmdFile=%~nx0
set ps1File=%cmdFile:.bat=.ps1%
set ps1FileLog=%ps1File:.ps1=.log%
if not exist "..\ps\log" mkdir ..\ps\log
powerShell -executionPolicy bypass -file "..\ps\lib\totvsGetDataModelPeriodAcc.ps1" %ps1File% 1> "..\ps\log\%ps1FileLog%" 2>&1
dir ..\ps\log\%ps1FileLog%
set /p hasError=<..\ps\log\%ps1FileLog%
if [%hasError%] NEQ [] (
  @echo on 
  echo %hasError% 
  timeout /T 3600 /NOBREAK > NUL
  start /b %cmdFile%
)