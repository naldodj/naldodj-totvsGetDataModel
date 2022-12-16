SELECT 
 DISTINCT SM0.M0_CODIGO
         ,SM0.M0_CODFIL
		 ,SM0.M0_FILIAL
		 ,SM0.M0_NOME
		 ,SM0.M0_NOMECOM 
     FROM SYS_COMPANY SM0
	 JOIN SRD990 SRD ON (SM0.M0_CODFIL=SRD.RD_FILIAL)
    WHERE SM0.D_E_L_E_T_=''
      AND SRD.D_E_L_E_T_=''
      AND (SM0.M0_CODFIL=SRD.RD_FILIAL)