SELECT 
 DISTINCT CTT.CTT_FILIAL 
         ,CTT.CTT_CUSTO
         ,CTT.CTT_DESC01 
     FROM CTT990 CTT
     JOIN SRD990 SRD ON (CTT.CTT_CUSTO=SRD.RD_CC)
	 JOIN SRV990 SRV ON (SRD.RD_PD=SRV.RV_COD AND ((CASE SRV.RV_FILIAL WHEN '' THEN 1 WHEN SRD.RD_FILIAL THEN 1 ELSE 0 END)=1) )	  
	 JOIN ZY_990 ZY_ ON (ZY_.ZY__CODIGO=SRV.RV_ZY__COD AND ((CASE ZY_.ZY__FILIAL WHEN '' THEN 1 WHEN SRV.RV_FILIAL THEN 1 ELSE 0 END)=1) )	  
    WHERE CTT.D_E_L_E_T_=''
      AND SRD.D_E_L_E_T_=''
	  AND SRV.D_E_L_E_T_=''
	  AND ZY_.D_E_L_E_T_=''      
      AND (CTT.CTT_FILIAL='' OR CTT.CTT_FILIAL=SRD.RD_FILIAL)
	  AND (SRV.RV_FILIAL=''  OR SRV.RV_FILIAL=SRD.RD_FILIAL)
	  AND (ZY_.ZY__FILIAL='' OR ZY_.ZY__FILIAL=SRD.RD_FILIAL)