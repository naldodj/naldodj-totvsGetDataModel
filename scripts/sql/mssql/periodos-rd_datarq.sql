WITH
    min_admissa AS (
        SELECT MIN(CONVERT(date,LEFT(SRA.RA_ADMISSA,6)+'01')) AS min_date
            FROM SRA990 SRA
            WHERE SRA.D_E_L_E_T_=''
    )
    ,numbers AS (
        SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS n
        FROM (
                SELECT TOP (DATEDIFF(MONTH,(
                                SELECT
                                        min_date
                                FROM
                                        min_admissa
                            )
                            ,GETDATE())) 1 AS X
                FROM sys.objects a
        CROSS JOIN sys.objects b
        CROSS JOIN sys.objects c
        ) x
    )
    ,months AS (
        SELECT
        FORMAT(
            DATEADD(MONTH,n,(
                    SELECT
                            min_date
                    FROM
                            min_admissa
            )
        ),'yyyyMM') AS PERIODO
        FROM numbers
    )
    SELECT DISTINCT
        months.PERIODO RD_DATARQ
    ,RIGHT(months.PERIODO,2)+'/'+LEFT(months.PERIODO,4) RD_MESANO
    ,LEFT(months.PERIODO,4)+'/'+RIGHT(months.PERIODO,2) RD_ANOMES
    ,(
        CASE RIGHT(months.PERIODO,2)
            WHEN '01' THEN 'JAN'
            WHEN '02' THEN 'FEV'
            WHEN '03' THEN 'MAR'
            WHEN '04' THEN 'ABR'
            WHEN '05' THEN 'MAI'
            WHEN '06' THEN 'JUN'
            WHEN '07' THEN 'JUL'
            WHEN '08' THEN 'AGO'
            WHEN '09' THEN 'SET'
            WHEN '10' THEN 'OUT'
            WHEN '11' THEN 'NOV'
            WHEN '12' THEN 'DEZ'
        END + LEFT(months.PERIODO,4)
        ) ALIASACM
     INTO !TABLENAME!
     FROM months
    WHERE months.PERIODO BETWEEN !DATARQDE! AND !DATARQATE!