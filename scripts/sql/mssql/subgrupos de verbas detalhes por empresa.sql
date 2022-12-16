		SELECT SRD.RD_DATARQ
          ,ZY_.ZY__MASTER
		  ,ZY_.ZY__CODIGO
		  ,ZY_.ZY__DESC
		  ,RTRIM(LTRIM(CONVERT(VARCHAR(1024),ZY_.ZY__HTML))) ZY__HTML
	  ,SUM(SRD.RD_VALOR) RD_VALOR
	  FROM SRA990 SRA
	  JOIN SRD990 SRD ON (SRA.RA_FILIAL=SRD.RD_FILIAL AND SRA.RA_MAT=SRD.RD_MAT)
	  JOIN SRV990 SRV ON (SRD.RD_PD=SRV.RV_COD)
	  JOIN ZY_990 ZY_ ON (SRV.RV_ZY__COD=ZY_.ZY__CODIGO)
	 WHERE SRA.D_E_L_E_T_=''
	   AND SRD.D_E_L_E_T_=' '
	   AND SRV.D_E_L_E_T_=' '
	   AND ZY_.D_E_L_E_T_=' '
	   AND (SRV.RV_FILIAL='' OR SRV.RV_FILIAL=SRD.RD_FILIAL)
	   AND SRD.RD_FILIAL=SRA.RA_FILIAL
	   AND SRD.RD_MAT=SRA.RA_MAT
	   AND SRV.RV_ZY__COD<>''
       AND SRD.RD_DATARQ BETWEEN !DATARQDE! AND !DATARQATE!
       AND ZY_.ZY__CODIGO BETWEEN !GRUPODE! AND !GRUPOATE!
	GROUP BY SRD.RD_DATARQ
            ,ZY_.ZY__MASTER
			,ZY_.ZY__CODIGO
			,ZY_.ZY__DESC
			,RTRIM(LTRIM(CONVERT(VARCHAR(1024),ZY_.ZY__HTML)))
