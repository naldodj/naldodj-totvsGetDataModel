BEGIN
    DECLARE @COMANDO_SQL  AS VARCHAR(MAX)
    DECLARE @COLUNAS_PIVOT AS VARCHAR(MAX)
    DECLARE @COLUNAS_PIVOT_SUM AS VARCHAR(MAX)
    DECLARE @COLUNAS_PIVOT_TOTAL AS VARCHAR(MAX)
    DECLARE @COLUNAS_PIVOT_NONULLS AS VARCHAR(MAX)
    DECLARE @DATARQDE AS VARCHAR(6)
    SET @DATARQDE=!DATARQDE!
    DECLARE @DATARQATE AS VARCHAR(6)
    SET @DATARQATE=!DATARQATE!
    DECLARE @CCDE AS VARCHAR(MAX)
    SET @CCDE=!CCDE!
    DECLARE @CCATE AS VARCHAR(MAX)
    SET @CCATE=!CCATE!
    DECLARE @FILIALDE AS VARCHAR(MAX)
    SET @FILIALDE=!FILIALDE!
    DECLARE @FILIALATE AS VARCHAR(MAX)
    SET @FILIALATE=!FILIALATE!
    DECLARE @GRUPODE AS VARCHAR(MAX)
    SET @GRUPODE=!GRUPODE!
    DECLARE @GRUPOATE AS VARCHAR(MAX)
    SET @GRUPOATE=!GRUPOATE!
    DECLARE @TTSNAME AS VARCHAR(MAX)
    SET @TTSNAME=!TTSNAME!
    DECLARE @TABLENAME AS VARCHAR(MAX)
    SET @TABLENAME=!TABLENAME!
    SET LANGUAGE Portuguese
BEGIN TRY
        SET @COLUNAS_PIVOT = STUFF((SELECT  ',' + QUOTENAME(RTRIM(LTRIM(cols_pivot.RD_DATARQ)))
        FROM (
                SELECT SRD.RD_DATARQ
                       ,SRD.RD_DATARQ YEARMONT
					   ,(ROW_NUMBER() OVER (PARTITION BY SRD.RD_DATARQ ORDER BY SRD.RD_DATARQ )) ID
				  FROM SRD990 SRD
                  JOIN SRV990 SRV ON (SRV.RV_COD=SRD.RD_PD)
                  JOIN ZY_990 ZY_ ON (ZY_.ZY__CODIGO=SRV.RV_ZY__COD)
                  JOIN SRA990 SRA ON (SRA.RA_FILIAL=SRD.RD_FILIAL AND SRA.RA_MAT=SRD.RD_MAT)
                 WHERE SRD.D_E_L_E_T_=''
                   AND SRA.D_E_L_E_T_=''
                   AND SRV.D_E_L_E_T_=''
                   AND ZY_.D_E_L_E_T_=''
                   AND ZY_.ZY__MASTER<>''
                   AND SRA.RA_FILIAL=SRD.RD_FILIAL
                   AND SRD.RD_DATARQ BETWEEN @DATARQDE AND @DATARQATE
                   AND SRD.RD_CC BETWEEN @CCDE AND @CCATE
                   AND SRD.RD_FILIAL BETWEEN @FILIALDE AND @FILIALATE
                   AND ZY_.ZY__MASTER BETWEEN @GRUPODE AND @GRUPOATE
                   AND ZY_.ZY__SQLFLD<>''
                   AND SRV.RV_FILIAL=(CASE SRV.RV_FILIAL WHEN '' THEN '' ELSE LEFT(SRD.RD_FILIAL,LEN(SRV.RV_FILIAL)) END)
                   AND ZY_.ZY__FILIAL=(CASE ZY_.ZY__FILIAL WHEN '' THEN '' ELSE LEFT(SRV.RV_FILIAL,LEN(ZY_.ZY__FILIAL)) END)
              GROUP BY SRD.RD_DATARQ
        ) cols_pivot ORDER BY YEARMONT,ID FOR XML PATH('') ), 1, 1, '')
        SET @COLUNAS_PIVOT_NONULLS='SELECT '+REPLACE(REPLACE(REPLACE(@COLUNAS_PIVOT,',',' UNION SELECT'),'[',''''),']',''' RD_DATARQ')
        EXECUTE('SELECT * INTO !PIVOTTABLENAME! FROM ('+@COLUNAS_PIVOT_NONULLS+') t')
        SET @COLUNAS_PIVOT_NONULLS = STUFF((SELECT DISTINCT ',ISNULL(' + QUOTENAME(RTRIM(LTRIM(cols_pivot_notnull.RD_DATARQ)))+',0)' + QUOTENAME(RTRIM(LTRIM(cols_pivot_notnull.RD_DATARQ)))
        FROM ( select * from !PIVOTTABLENAME! ) cols_pivot_notnull FOR XML PATH('')), 1, 1, '')
        SET @COLUNAS_PIVOT_SUM = STUFF((SELECT DISTINCT ',ISNULL(SUM(' + QUOTENAME(RTRIM(LTRIM(cols_pivot_sum.RD_DATARQ)))+'),0)' + QUOTENAME(RTRIM(LTRIM(CONCAT(UPPER(LEFT(DATENAME(MONTH,CAST(CONCAT(cols_pivot_sum.RD_DATARQ,'01') AS DATETIME)),3)),LEFT(cols_pivot_sum.RD_DATARQ,4)))))
        FROM ( select * from !PIVOTTABLENAME! ) cols_pivot_sum FOR XML PATH('')), 1, 1, '')
        SET @COLUNAS_PIVOT_TOTAL = STUFF((SELECT DISTINCT ',ISNULL(' + QUOTENAME(RTRIM(LTRIM(cols_pivot_total.RD_DATARQ)))+',0)'
        FROM ( select * from !PIVOTTABLENAME! ) cols_pivot_total FOR XML PATH('')), 1, 1, '')
        SET @COLUNAS_PIVOT_TOTAL=REPLACE(REPLACE(@COLUNAS_PIVOT_TOTAL,',','+'),'+0',',0')
        DROP TABLE !PIVOTTABLENAME!
        SET @COMANDO_SQL = '
             SELECT t.RD_FILIAL
                   ,t.RD_CC
                   ,t.CTT_DESC01
                   ,t.ZY__MASTER
                   ,ZY_.ZY__DESC
                   ,'+@COLUNAS_PIVOT_SUM+'
                   ,TOTAL=SUM(t.TOTAL)
              FROM (
                    SELECT t.RD_FILIAL
                          ,t.RD_CC
                          ,t.CTT_DESC01
                          ,t.ZY__MASTER
                          ,'+@COLUNAS_PIVOT_NONULLS+'
                          ,TOTAL=SUM('+@COLUNAS_PIVOT_TOTAL+')
                     FROM
                    (SELECT * FROM
                        (
                            SELECT SRD.RD_FILIAL
                                  ,SRD.RD_DATARQ
                                  ,SRD.RD_CC
								  ,CTT.CTT_DESC01
                                  ,ZY_.ZY__MASTER
                                  ,SUM(SRD.RD_VALOR) RD_VALOR
                            FROM SRA990 SRA
                            JOIN SRD990 SRD ON (SRA.RA_FILIAL=SRD.RD_FILIAL AND SRA.RA_MAT=SRD.RD_MAT)
                            JOIN SRV990 SRV ON (SRV.RV_COD=SRD.RD_PD)
                            JOIN ZY_990 ZY_ ON (ZY_.ZY__CODIGO=SRV.RV_ZY__COD)
                            JOIN CTT990 CTT ON (CTT.CTT_CUSTO=SRD.RD_CC)
                            WHERE SRD.D_E_L_E_T_=''''
                              AND SRA.D_E_L_E_T_=''''
                              AND SRV.D_E_L_E_T_=''''
                              AND ZY_.D_E_L_E_T_=''''
                              AND CTT.D_E_L_E_T_=''''
                              AND SRA.RA_FILIAL=SRD.RD_FILIAL
                              AND SRD.RD_DATARQ BETWEEN '''+@DATARQDE+''' AND '''+@DATARQATE+'''
                              AND SRD.RD_CC BETWEEN '''+@CCDE+''' AND '''+@CCATE+'''
                              AND SRD.RD_FILIAL BETWEEN '''+@FILIALDE+''' AND '''+@FILIALATE+'''
                              AND ZY_.ZY__MASTER BETWEEN '''+@GRUPODE+''' AND '''+@GRUPOATE+'''
                              AND ZY_.ZY__SQLFLD<>''''
                              AND SRV.RV_FILIAL=(CASE SRV.RV_FILIAL WHEN '''' THEN '''' ELSE LEFT(SRD.RD_FILIAL,LEN(SRV.RV_FILIAL)) END)
                              AND ZY_.ZY__FILIAL=(CASE ZY_.ZY__FILIAL WHEN '''' THEN '''' ELSE LEFT(SRV.RV_FILIAL,LEN(ZY_.ZY__FILIAL)) END)
                              AND CTT.CTT_FILIAL=(CASE CTT.CTT_FILIAL WHEN '''' THEN '''' ELSE LEFT(SRD.RD_FILIAL,LEN(CTT.CTT_FILIAL)) END)
                         GROUP BY SRD.RD_FILIAL,SRD.RD_DATARQ,RD_CC,CTT.CTT_DESC01,ZY_.ZY__MASTER
                        ) ROW
                    PIVOT (SUM(ROW.RD_VALOR) FOR ROW.RD_DATARQ IN (' + @COLUNAS_PIVOT + ')) COL ) t
                    GROUP BY t.RD_FILIAL,t.RD_CC,t.CTT_DESC01,t.ZY__MASTER,t.'+@COLUNAS_PIVOT+') t
             JOIN ZY_990 ZY_ ON (ZY_.ZY__CODIGO=t.ZY__MASTER AND ZY_.ZY__FILIAL=(CASE ZY_.ZY__FILIAL WHEN '''' THEN '''' ELSE LEFT(t.RD_FILIAL,LEN(ZY_.ZY__FILIAL)) END))
             GROUP BY t.RD_FILIAL,t.RD_CC,t.CTT_DESC01,t.ZY__MASTER,ZY_.ZY__DESC'
            BEGIN TRANSACTION @TTSNAME
                EXECUTE('SELECT * INTO '+@TABLENAME+' FROM ('+@COMANDO_SQL+') t')
            COMMIT TRANSACTION @TTSNAME
	END TRY
BEGIN CATCH
			EXECUTE('SELECT * INTO '+@TABLENAME+' FROM (SELECT '''' RD_FILIAL,'''' RD_CC,'''' CTT_DESC01,'''' ZY__MASTER,'''' ZY__DESC,0 TOTAL ) t')
	END CATCH;
END