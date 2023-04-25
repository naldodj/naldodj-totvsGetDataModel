@echo off

:: Loop através de todos os arquivos .xml no diretório '..\tsk'
FOR %%G in ("..\tsk\*.xml") DO (

    :: Verificando se a tarefa agendada existe
    schtasks.exe /Query /TN "%%~nG" > NUL 2>&1

    :: Modificando a tarefa agendada existente ou criando uma nova caso não exista
    IF ERRORLEVEL 1 (
        schtasks.exe /Create /XML "%%G" /RU "SYSTEM" /TN "%%~nG" || echo.
    ) ELSE (
        schtasks.exe /Change /TN "%%~nG" /RU "SYSTEM" || echo.
    )
)
