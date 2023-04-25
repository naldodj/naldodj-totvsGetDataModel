@echo off

:: Loop através de todos os arquivos .bat no diretório atual
FOR %%G in ("*.bat") DO (

    :: Verificando se o arquivo .bat não é 'all.bat'
    IF NOT %%~nxG==all.bat (

        :: Verificando se o arquivo .bat não é 'DEPARTAMENTOS_SRA.bat'
        IF NOT %%~nxG==DEPARTAMENTOS_SRA.bat (

            :: Verificando se o arquivo .bat não é 'CreateTasks.bat'
            IF NOT %%~nxG==CreateTasks.bat (

                :: Chamando o arquivo .bat e exibindo uma linha vazia em caso de erro
                call %%~nxG || echo.
            )
        )
    )
)
