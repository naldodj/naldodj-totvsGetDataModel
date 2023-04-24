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
    DECLARE @MESPROV AS VARCHAR(2)=RIGHT(@DATARQDE,2)
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
    BEGIN TRY
        SET @COLUNAS_PIVOT = STUFF((SELECT DISTINCT ',' + QUOTENAME(RTRIM(LTRIM(cols_pivot.ZY__SQLFLD)))
        FROM (
                SELECT DISTINCT ZY_.ZY__SQLFLD
                  FROM SRD990 SRD
                  JOIN SRV990 SRV ON (SRV.RV_COD=SRD.RD_PD)
                  JOIN ZY_990 ZY_ ON (ZY_.ZY__CODIGO=SRV.RV_ZY__COD)
                  JOIN SRA990 SRA ON (SRA.RA_FILIAL=SRD.RD_FILIAL AND SRA.RA_MAT=SRD.RD_MAT)
                WHERE SRD.D_E_L_E_T_=''
                   AND SRA.D_E_L_E_T_=''
                   AND SRV.D_E_L_E_T_=''
                   AND ZY_.D_E_L_E_T_=''
                   AND SRA.RA_FILIAL=SRD.RD_FILIAL
                   AND SRD.RD_DATARQ BETWEEN @DATARQDE AND @DATARQATE
                   AND SRD.RD_FILIAL BETWEEN @FILIALDE AND @FILIALATE
                   AND ZY_.ZY__CODIGO BETWEEN @GRUPODE AND @GRUPOATE
                   AND ZY_.ZY__SQLFLD<>''
                   AND SRV.RV_FILIAL=(CASE SRV.RV_FILIAL WHEN '' THEN '' ELSE LEFT(SRD.RD_FILIAL,LEN(SRV.RV_FILIAL)) END)
                   AND ZY_.ZY__FILIAL=(CASE ZY_.ZY__FILIAL WHEN '' THEN '' ELSE LEFT(SRV.RV_FILIAL,LEN(ZY_.ZY__FILIAL)) END)
        ) cols_pivot FOR XML PATH('')), 1, 1, '')
        SET @COLUNAS_PIVOT_NONULLS='SELECT '+REPLACE(REPLACE(REPLACE(@COLUNAS_PIVOT,',',' UNION SELECT'),'[',''''),']',''' ZY__SQLFLD')
        EXECUTE('SELECT * INTO !PIVOTTABLENAME! FROM ('+@COLUNAS_PIVOT_NONULLS+') t')
        SET @COLUNAS_PIVOT_NONULLS = STUFF((SELECT DISTINCT ',ISNULL(' + QUOTENAME(RTRIM(LTRIM(cols_pivot_notnull.ZY__SQLFLD)))+',0)' + QUOTENAME(RTRIM(LTRIM(cols_pivot_notnull.ZY__SQLFLD)))
        FROM ( select * from !PIVOTTABLENAME! ) cols_pivot_notnull FOR XML PATH('')), 1, 1, '')
        SET @COLUNAS_PIVOT_SUM = STUFF((SELECT DISTINCT ',ISNULL(SUM(' + QUOTENAME(RTRIM(LTRIM(cols_pivot_sum.ZY__SQLFLD)))+'),0)' + QUOTENAME(RTRIM(LTRIM(cols_pivot_sum.ZY__SQLFLD)))
        FROM ( select * from !PIVOTTABLENAME! ) cols_pivot_sum FOR XML PATH('')), 1, 1, '')
        SET @COLUNAS_PIVOT_TOTAL = STUFF((SELECT DISTINCT ',ISNULL(' + QUOTENAME(RTRIM(LTRIM(cols_pivot_total.ZY__SQLFLD)))+',0)'
        FROM ( select * from !PIVOTTABLENAME! ) cols_pivot_total FOR XML PATH('')), 1, 1, '')
        SET @COLUNAS_PIVOT_TOTAL=REPLACE(REPLACE(@COLUNAS_PIVOT_TOTAL,',','+'),'+0',',0')
        DROP TABLE !PIVOTTABLENAME!
        SET @COMANDO_SQL = '
             SELECT t.RD_DATARQ
                   ,'+@COLUNAS_PIVOT_SUM+'
                   ,SUBTOTAL=SUM(t.SUBTOTAL)
                   ,PROV13S=SUM(t.PROV13S)
                   ,PROVFER=SUM(t.PROVFER)
                   ,PROVRES=SUM(t.PROVRES)
                   ,PROVTOT=SUM(t.PROVTOT)
                   ,TOTAL=SUM(t.TOTAL)
              FROM (
                    SELECT t.RD_DATARQ
                          ,'+@COLUNAS_PIVOT_NONULLS+'
                          ,SUBTOTAL=SUM('+@COLUNAS_PIVOT_TOTAL+')
                          ,PROV13S=SUM(t.PROV13S)
                          ,PROVFER=SUM(t.PROVFER)
                          ,PROVRES=SUM(t.PROVRES)
                          ,PROVTOT=SUM(t.PROV13S+t.PROVFER+t.PROVRES)
                          ,TOTAL=SUM('+@COLUNAS_PIVOT_TOTAL+'+t.PROV13S+t.PROVFER+t.PROVRES)
                        FROM
                    (SELECT * FROM
                        (
                            SELECT SRD.RD_DATARQ
                                  ,ZY_.ZY__SQLFLD
                                  ,SUM(SRD.RD_VALOR) RD_VALOR
                                  ,(CASE SUM(ZY_.ZY__PROV13) WHEN 0 THEN 0 ELSE (CASE MIN(ZY_.ZY__FPR13S) WHEN ''2'' THEN ROUND(SUM(ZY_.ZY__PROV13*'+@MESPROV+'*SRD.RD_VALOR),2) ELSE ROUND(SUM(ZY_.ZY__PROV13*SRD.RD_VALOR),2) END) END) PROV13S
                                  ,(CASE SUM(ZY_.ZY__PROVFE) WHEN 0 THEN 0 ELSE (CASE MIN(ZY_.ZY__FPRFER) WHEN ''2'' THEN ROUND(SUM(ZY_.ZY__PROVFE*'+@MESPROV+'*SRD.RD_VALOR),2) ELSE ROUND(SUM(ZY_.ZY__PROVFE*SRD.RD_VALOR),2) END) END) PROVFER
                                  ,(CASE SUM(ZY_.ZY__PROVRE) WHEN 0 THEN 0 ELSE (CASE MIN(ZY_.ZY__FPRRES) WHEN ''2'' THEN ROUND(SUM(ZY_.ZY__PROVRE*'+@MESPROV+'*SRD.RD_VALOR),2) ELSE ROUND(SUM(ZY_.ZY__PROVRE*SRD.RD_VALOR),2) END) END) PROVRES
                              FROM SRA990 SRA
                            JOIN SRD990 SRD ON (SRA.RA_FILIAL=SRD.RD_FILIAL AND SRA.RA_MAT=SRD.RD_MAT)
                            JOIN SRV990 SRV ON (SRV.RV_COD=SRD.RD_PD)
                            JOIN ZY_990 ZY_ ON (ZY_.ZY__CODIGO=SRV.RV_ZY__COD)
                           WHERE SRD.D_E_L_E_T_='' ''
                             AND SRA.D_E_L_E_T_='' ''
                             AND SRV.D_E_L_E_T_='' ''
                             AND ZY_.D_E_L_E_T_='' ''
                             AND SRA.RA_FILIAL=SRD.RD_FILIAL
                             AND SRD.RD_DATARQ BETWEEN '''+@DATARQDE+''' AND '''+@DATARQATE+'''
                             AND SRD.RD_FILIAL BETWEEN '''+@FILIALDE+''' AND '''+@FILIALATE+'''
                             AND ZY_.ZY__CODIGO BETWEEN '''+@GRUPODE+''' AND '''+@GRUPOATE+'''
                             AND ZY_.ZY__SQLFLD<>''''
                             AND SRV.RV_FILIAL=(CASE SRV.RV_FILIAL WHEN '''' THEN '''' ELSE LEFT(SRD.RD_FILIAL,LEN(SRV.RV_FILIAL)) END)
                             AND ZY_.ZY__FILIAL=(CASE ZY_.ZY__FILIAL WHEN '''' THEN '''' ELSE LEFT(SRV.RV_FILIAL,LEN(ZY_.ZY__FILIAL)) END)
                         GROUP BY SRD.RD_DATARQ,ZY_.ZY__SQLFLD
                        ) ROW
                    PIVOT (SUM(ROW.RD_VALOR) FOR ZY__SQLFLD IN (' + @COLUNAS_PIVOT + ')) COL  ) t
                    GROUP BY t.RD_DATARQ,'+@COLUNAS_PIVOT+') t
             GROUP BY t.RD_DATARQ'
             BEGIN TRANSACTION @TTSNAME
              EXECUTE('SELECT * INTO '+@TABLENAME+' FROM ('+@COMANDO_SQL+') t')
             COMMIT TRANSACTION @TTSNAME
	END TRY
	BEGIN CATCH
			EXECUTE('SELECT * INTO '+@TABLENAME+' FROM (SELECT '''' RD_DATARQ,SUBTOTAL=0,PROV13S=0,PROVFER=0,PROVRES=0,PROVTOT=0,TOTAL=0 ) t')
	END CATCH;
END