SELECT 
DISTINCT SQB.QB_FILIAL
         ,SQB.QB_DEPTO
         ,SQB.QB_DESCRIC
     FROM SQB990 SQB
	 JOIN SRA990 SRA ON (SQB.QB_DEPTO=SRA.RA_DEPTO AND ((CASE SQB.QB_FILIAL WHEN '' THEN 1 WHEN SRA.RA_FILIAL THEN 1 ELSE 0 END)=1) )
    WHERE SQB.D_E_L_E_T_=''
      AND SRA.D_E_L_E_T_=''
      AND (SQB.QB_DEPTO=SRA.RA_DEPTO AND ((CASE SQB.QB_FILIAL WHEN '' THEN 1 WHEN SRA.RA_FILIAL THEN 1 ELSE 0 END)=1) )