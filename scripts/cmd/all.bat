@Echo Off
FOR %%G in ("*.bat") DO (
    IF NOT %%~nxG==all.bat (
        IF NOT %%~nxG==DEPARTAMENTOS_SRA.bat (
            call %%~nxG
        )    
    )
)    