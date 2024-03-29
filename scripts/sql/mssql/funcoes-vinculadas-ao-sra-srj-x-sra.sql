SELECT 
DISTINCT  SRJ.RJ_FILIAL
         ,SRJ.RJ_FUNCAO
         ,SRJ.RJ_DESC
     FROM SRJ990 SRJ 
     JOIN SRA990 SRA ON (SRJ.RJ_FUNCAO=SRA.RA_CODFUNC)
    WHERE SRJ.D_E_L_E_T_=''
      AND SRA.D_E_L_E_T_=''
      AND SRJ.RJ_FUNCAO=SRA.RA_CODFUNC 
      AND SRJ.RJ_FILIAL=(CASE SRJ.RJ_FILIAL WHEN ' ' THEN ' ' ELSE LEFT(SRA.RA_FILIAL,LEN(SRJ.RJ_FILIAL)) END)
