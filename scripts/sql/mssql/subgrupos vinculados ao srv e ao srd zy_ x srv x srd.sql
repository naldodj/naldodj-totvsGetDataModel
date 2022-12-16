SELECT
 DISTINCT ZY_.ZY__FILIAL
         ,ZY_.ZY__CODIGO
         ,ZY_.ZY__SQLFLD
         ,ZY_.ZY__DESC
         ,ZY_.ZY__MASTER
         ,RTRIM(LTRIM(CONVERT(VARCHAR(1024),ZY_.ZY__HTML))) ZY__HTML
         ,ISNULL((CASE ZY_.ZY__MASTER WHEN '' THEN '' ELSE (SELECT DISTINCT ZY_M.ZY__DESC FROM ZY_990 ZY_M WHERE ZY_M.D_E_L_E_T_= '' AND ZY_.ZY__FILIAL=ZY_M.ZY__FILIAL AND ZY_.ZY__MASTER=ZY_M.ZY__CODIGO ) END ),'') DESCMASTER
         ,ISNULL((CASE ZY_.ZY__MASTER WHEN '' THEN '' ELSE (SELECT DISTINCT RTRIM(LTRIM(CONVERT(VARCHAR(1024),ZY_M.ZY__HTML))) FROM ZY_990 ZY_M WHERE ZY_M.D_E_L_E_T_= '' AND ZY_.ZY__FILIAL=ZY_M.ZY__FILIAL AND ZY_.ZY__MASTER=ZY_M.ZY__CODIGO ) END ),'') HTMLMASTER
         ,ZY_.ZY__PROV13
         ,ZY_.ZY__PROVFE
         ,ZY_.ZY__PROVRE
     FROM ZY_990 ZY_
     JOIN SRV990 SRV ON (ZY_.ZY__CODIGO=SRV.RV_ZY__COD AND ((CASE ZY_.ZY__FILIAL WHEN '' THEN 1 WHEN SRV.RV_FILIAL THEN 1 ELSE 0 END)=1) )
     JOIN SRD990 SRD ON (SRV.RV_COD=SRD.RD_PD AND ((CASE ZY_.ZY__FILIAL WHEN '' THEN 1 WHEN SRD.RD_FILIAL THEN 1 ELSE 0 END)=1) )
    WHERE ZY_.D_E_L_E_T_=''
      AND SRV.D_E_L_E_T_=''
      AND SRD.D_E_L_E_T_=''
      AND (ZY_.ZY__FILIAL='' OR ZY_.ZY__FILIAL=SRV.RV_FILIAL)
      AND (SRV.RV_FILIAL='' OR SRV.RV_FILIAL=SRD.RD_FILIAL)
