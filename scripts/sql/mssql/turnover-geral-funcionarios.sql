BEGIN
    WITH
       min_admissa AS (
            SELECT MIN(CONVERT(date,LEFT(SRA.RA_ADMISSA,6)+'01')) AS min_date
              FROM SRA990 SRA
             WHERE SRA.D_E_L_E_T_=''
               AND SRA.RA_FILIAL BETWEEN !FILIALDE! AND !FILIALATE!
               AND SRA.RA_CC BETWEEN !CCDE! AND !CCATE!
               AND SRA.RA_CODFUNC BETWEEN !FUNCAODE! AND !FUNCAOATE!
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
            SELECT DISTINCT
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
    SELECT *
      INTO !TBLTMPMONTHS!
      FROM months
    BEGIN
        WITH PERIODO  AS (
                SELECT DISTINCT
                       months.PERIODO
                      ,SRA.RA_FILIAL
                      ,SRA.RA_CC
                      ,SRA.RA_CODFUNC
                      ,SRA.RA_MAT
                      ,SRA.R_E_C_N_O_ SRARECNO
                FROM SRA990 SRA
          CROSS JOIN !TBLTMPMONTHS! months
               WHERE SRA.D_E_L_E_T_=''
                 AND SRA.RA_FILIAL BETWEEN !FILIALDE! AND !FILIALATE!
                 AND SRA.RA_CC BETWEEN !CCDE! AND !CCATE!
                 AND SRA.RA_CODFUNC BETWEEN !FUNCAODE! AND !FUNCAOATE!
                 AND (
                       LEFT(SRA.RA_ADMISSA,6)<=months.PERIODO
                       AND (
                           SRA.RA_DEMISSA=''
                           OR
                           LEFT(SRA.RA_DEMISSA,6)>=months.PERIODO
                       )
                  )
             GROUP BY months.PERIODO
                     ,SRA.RA_FILIAL
                     ,SRA.RA_CC
                     ,SRA.RA_CODFUNC
                     ,SRA.RA_MAT
                     ,SRA.R_E_C_N_O_
             )
           ,TURNOVER AS (
                    SELECT DISTINCT
                          PERIODO.PERIODO
                         ,PERIODO.RA_FILIAL
                         ,PERIODO.RA_CC
                         ,CTT.CTT_DESC01
                         ,PERIODO.RA_CODFUNC
                         ,SRJ.RJ_DESC
                         ,PERIODO.RA_MAT
                         ,PERIODO.SRARECNO
                         ,ISNULL(
                         (
                          SELECT SUM(TTRFSAI)
                            FROM (
                                  SELECT COUNT(1) AS TTRFSAI
                                    FROM SRE990 SRE_T
                                   WHERE SRE_T.D_E_L_E_T_=''
                                     AND SRE_T.RE_EMPD=!EMPRESA!
                                     AND LEFT(SRE_T.RE_DATA,6)=PERIODO.PERIODO
                                     AND SRE_T.RE_FILIALD=PERIODO.RA_FILIAL
                                     AND SRE_T.RE_CCD=PERIODO.RA_CC
                                     AND SRE_T.RE_MATD=PERIODO.RA_MAT
                                GROUP BY LEFT(SRE_T.RE_DATA,6)
                                        ,SRE_T.RE_EMPD
                                        ,SRE_T.RE_FILIALD
                                        ,SRE_T.RE_CCD
                                        ,SRE_T.RE_MATD
                             ) T
                         ),0) TTRFSAI
                         ,ISNULL(
                         (
                          SELECT SUM(TTRFENT)
                            FROM
                             (
                                  SELECT COUNT(1) AS TTRFENT
                                    FROM SRE990 SRE_T
                                   WHERE SRE_T.D_E_L_E_T_=''
                                     AND SRE_T.RE_EMPP=!EMPRESA!
                                     AND LEFT(SRE_T.RE_DATA,6)=PERIODO.PERIODO
                                     AND SRE_T.RE_FILIALP=PERIODO.RA_FILIAL
                                     AND SRE_T.RE_CCP=PERIODO.RA_CC
                                     AND SRE_T.RE_MATP=PERIODO.RA_MAT
                                GROUP BY LEFT(SRE_T.RE_DATA,6)
                                        ,SRE_T.RE_EMPP
                                        ,SRE_T.RE_FILIALP
                                        ,SRE_T.RE_CCP
                                        ,SRE_T.RE_MATP
                             ) T
                         ),0) TTRFENT
                         ,ISNULL(
                         (
                          SELECT SUM(TFUNMES)
                            FROM
                                 (
                                    SELECT COUNT(1) AS TFUNMES
                                      FROM SRA990 SRA_T
                                     WHERE SRA_T.D_E_L_E_T_=''
                                       AND LEFT(SRA_T.RA_ADMISSA,6)<=PERIODO.PERIODO
                                       AND (
                                              SRA_T.RA_DEMISSA=''
                                              OR
                                               (
                                                    LEFT(SRA_T.RA_ADMISSA,6)<=LEFT(SRA_T.RA_DEMISSA,6)
                                                    AND LEFT(SRA_T.RA_DEMISSA,6)>=PERIODO.PERIODO
                                               )
                                       )
                                       AND SRA_T.RA_FILIAL=PERIODO.RA_FILIAL
                                       AND SRA_T.RA_CC=PERIODO.RA_CC
                                       AND SRA_T.RA_CODFUNC=PERIODO.RA_CODFUNC
                                       AND SRA_T.RA_MAT=PERIODO.RA_MAT
                                       AND SRA_T.R_E_C_N_O_=PERIODO.SRARECNO
                                 ) T
                         ),0) TFUNMES
                         ,ISNULL(
                         (
                              SELECT SUM(ADMISSAO)
                                FROM
                                 (
                                      SELECT COUNT(SRA_A.RA_ADMISSA) AS ADMISSAO
                                        FROM SRA990 SRA_A
                                       WHERE LEFT(SRA_A.RA_ADMISSA,6)=PERIODO.PERIODO
                                         AND SRA_A.RA_FILIAL=PERIODO.RA_FILIAL
                                         AND SRA_A.RA_CC=PERIODO.RA_CC
                                         AND SRA_A.RA_CODFUNC=PERIODO.RA_CODFUNC
                                         AND SRA_A.RA_MAT=PERIODO.RA_MAT
                                    GROUP BY LEFT(SRA_A.RA_ADMISSA,6)
                                            ,SRA_A.RA_FILIAL
                                            ,SRA_A.RA_CC
                                            ,SRA_A.RA_CODFUNC
                                            ,SRA_A.RA_MAT
                                 ) T
                         ),0) TFUNADMMES
                         ,ISNULL(
                         (
                              SELECT SUM(DEMISSAO)
                              FROM (
                                  SELECT COUNT(RA_DEMISSA) AS DEMISSAO
                                    FROM SRA990 SRA_D
                                   WHERE SRA_D.RA_DEMISSA<>''
                                     AND LEFT(SRA_D.RA_DEMISSA,6)=PERIODO.PERIODO
                                     AND SRA_D.RA_CC=PERIODO.RA_CC
                                     AND SRA_D.RA_CODFUNC=PERIODO.RA_CODFUNC
                                     AND SRA_D.RA_MAT=PERIODO.RA_MAT
                                     AND SRA_D.RA_DEMISSA<>''
                                     AND SRA_D.R_E_C_N_O_=PERIODO.SRARECNO
                               GROUP BY LEFT(SRA_D.RA_DEMISSA,6)
                                       ,SRA_D.RA_FILIAL
                                       ,SRA_D.RA_CC
                                       ,SRA_D.RA_CODFUNC
                                       ,SRA_D.RA_MAT
                              ) T
                         ),0) TFUNDEMMES
                    FROM PERIODO
                    JOIN CTT990 CTT ON (PERIODO.RA_CC=CTT.CTT_CUSTO)
                    JOIN SRJ990 SRJ ON (PERIODO.RA_CODFUNC=SRJ.RJ_FUNCAO)
                   WHERE PERIODO.PERIODO BETWEEN !DATARQDE! AND !DATARQATE!
                     AND PERIODO.RA_FILIAL BETWEEN !FILIALDE! AND !FILIALATE!
                     AND PERIODO.RA_CC BETWEEN !CCDE! AND !CCATE!
                     AND PERIODO.RA_CODFUNC BETWEEN !FUNCAODE! AND !FUNCAOATE!
                     AND CTT.CTT_FILIAL=(CASE CTT.CTT_FILIAL WHEN '' THEN '' ELSE LEFT(PERIODO.RA_FILIAL,LEN(CTT.CTT_FILIAL)) END)
                     AND SRJ.RJ_FILIAL=(CASE SRJ.RJ_FILIAL WHEN '' THEN '' ELSE LEFT(PERIODO.RA_FILIAL,LEN(SRJ.RJ_FILIAL)) END)
             )
           ,TURNOVERT AS (
                SELECT DISTINCT
                       TURNOVER.PERIODO
                      ,TURNOVER.RA_FILIAL
                      ,TURNOVER.RA_CC
                      ,TURNOVER.CTT_DESC01
                      ,TURNOVER.RA_CODFUNC
                      ,TURNOVER.RJ_DESC
                      ,TURNOVER.RA_MAT
                      ,TURNOVER.SRARECNO
                      ,TTRFSAI=SUM(TURNOVER.TTRFSAI)
                      ,TTRFENT=SUM(TURNOVER.TTRFENT)
                      ,TFUNIMES=SUM(CAST((TURNOVER.TFUNMES-TURNOVER.TFUNADMMES) AS FLOAT))
                      ,TFUNADMMES=SUM(CAST(TURNOVER.TFUNADMMES AS FLOAT))
                      ,TFUNMES=SUM(CAST(TURNOVER.TFUNMES AS FLOAT))
                      ,TFUNDEMMES=SUM(CAST(TURNOVER.TFUNDEMMES AS FLOAT))
                      ,TFUNFMES=SUM(CAST((TURNOVER.TFUNMES-TURNOVER.TFUNDEMMES) AS FLOAT))
                FROM TURNOVER
                GROUP 
                   BY  TURNOVER.PERIODO
                      ,TURNOVER.RA_FILIAL
                      ,TURNOVER.RA_CC
                      ,TURNOVER.CTT_DESC01
                      ,TURNOVER.RA_CODFUNC
                      ,TURNOVER.RJ_DESC
                      ,TURNOVER.RA_MAT
                      ,TURNOVER.SRARECNO
            )
        SELECT DISTINCT
              TURNOVERT.PERIODO
             ,TURNOVERT.RA_FILIAL
             ,TURNOVERT.RA_CC
             ,TURNOVERT.CTT_DESC01
             ,TURNOVERT.RA_CODFUNC
             ,TURNOVERT.RJ_DESC
             ,TURNOVERT.RA_MAT
             ,TURNOVERT.SRARECNO
             ,TURNOVERT.TTRFSAI
             ,TURNOVERT.TTRFENT
             ,TURNOVERT.TFUNIMES
             ,TURNOVERT.TFUNADMMES
             ,TURNOVERT.TFUNMES
             ,TURNOVERT.TFUNDEMMES
             ,TURNOVERT.TFUNFMES
             ,TURNOVER=ROUND(((CASE TFUNIMES WHEN 0 THEN 0 ELSE ((TURNOVERT.TFUNADMMES+TURNOVERT.TFUNDEMMES)/2/TURNOVERT.TFUNIMES) END)*100),2)
             ,TURNMOVF=ROUND(((CASE TFUNIMES WHEN 0 THEN 0 ELSE (TURNOVERT.TFUNDEMMES)/2/TURNOVERT.TFUNIMES END)*100),2)
        INTO !TABLENAME!
        FROM TURNOVERT
    END
    DROP TABLE !TBLTMPMONTHS!
END