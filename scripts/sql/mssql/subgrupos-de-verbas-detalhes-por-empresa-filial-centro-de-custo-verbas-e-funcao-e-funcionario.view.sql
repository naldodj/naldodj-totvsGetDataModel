--Set the options to support indexed views.
SET NUMERIC_ROUNDABORT OFF;
SET ANSI_PADDING, ANSI_WARNINGS, CONCAT_NULL_YIELDS_NULL, ARITHABORT,
   QUOTED_IDENTIFIER, ANSI_NULLS ON;
--Create view with schemabinding.
IF OBJECT_ID ('dbo.v99GRPVERBASFUNCIONARIOS', 'view') IS NOT NULL
begin
    DROP VIEW dbo.v99GRPVERBASFUNCIONARIOS ;
end
GO
CREATE VIEW dbo.v99GRPVERBASFUNCIONARIOS
   WITH SCHEMABINDING
   AS  
     SELECT SRA.RA_FILIAL
          ,SRD.RD_DATARQ
          ,SRD.RD_CC
          ,CTT.CTT_DESC01
          ,ZY_.ZY__MASTER
          ,ZY_.ZY__CODIGO
          ,ZY_.ZY__DESC
		  ,RTRIM(LTRIM(CONVERT(VARCHAR(1024),ZY_.ZY__HTML))) ZY__HTML
          ,SRV.RV_COD
          ,SRV.RV_DESC
          ,SRJ.RJ_FUNCAO
          ,SRJ.RJ_DESC
          ,SRA.RA_MAT
          ,SRA.RA_NOME
          ,SUM(SRD.RD_VALOR) RD_VALOR
          ,COUNT_BIG(*) as tmp
     FROM dbo.SRA990 SRA
     JOIN dbo.SRD990 SRD ON (SRA.RA_FILIAL=SRD.RD_FILIAL AND SRA.RA_MAT=SRD.RD_MAT)
     JOIN dbo.CTT990 CTT ON (CTT.CTT_CUSTO=SRD.RD_CC)
     JOIN dbo.SRV990 SRV ON (SRD.RD_PD=SRV.RV_COD)
     JOIN dbo.ZY_990 ZY_ ON (SRV.RV_ZY__COD=ZY_.ZY__CODIGO)
     JOIN dbo.SRJ990 SRJ ON (SRA.RA_CODFUNC=SRJ.RJ_FUNCAO)
    WHERE SRA.D_E_L_E_T_=''
      AND SRD.D_E_L_E_T_=' '
      AND SRV.D_E_L_E_T_=' '
      AND ZY_.D_E_L_E_T_=' '
      AND SRJ.D_E_L_E_T_=''
      AND (CTT.CTT_FILIAL='' OR CTT.CTT_FILIAL=SRD.RD_CC)
      AND (SRV.RV_FILIAL='' OR SRV.RV_FILIAL=SRD.RD_FILIAL)
      AND (SRJ.RJ_FILIAL='' OR SRJ.RJ_FILIAL=SRA.RA_FILIAL)
      AND SRD.RD_FILIAL=SRA.RA_FILIAL
      AND SRD.RD_MAT=SRA.RA_MAT
      AND SRV.RV_ZY__COD<>''
     GROUP BY SRA.RA_FILIAL
            ,SRD.RD_DATARQ
            ,SRD.RD_CC
            ,CTT.CTT_DESC01
            ,ZY_.ZY__MASTER
            ,ZY_.ZY__CODIGO
            ,ZY_.ZY__DESC
			,RTRIM(LTRIM(CONVERT(VARCHAR(1024),ZY_.ZY__HTML)))
            ,SRV.RV_COD
            ,SRV.RV_DESC
            ,SRJ.RJ_FUNCAO
            ,SRJ.RJ_DESC
            ,SRA.RA_MAT
            ,SRA.RA_NOME;
GO
--Create an index on the view.
IF OBJECT_ID ('dbo.v99GRPVERBASFUNCIONARIOS', 'view') IS NOT NULL
begin
    CREATE UNIQUE CLUSTERED INDEX IDX_vGRPVERBASFUNCIONARIOS ON dbo.v99GRPVERBASFUNCIONARIOS (
             RA_FILIAL
            ,RD_DATARQ
            ,RD_CC
            ,CTT_DESC01
			,ZY__MASTER
            ,ZY__CODIGO
            ,ZY__DESC
            ,RV_COD
            ,RV_DESC
            ,RJ_FUNCAO
            ,RJ_DESC
            ,RA_MAT
            ,RA_NOME
    );
end