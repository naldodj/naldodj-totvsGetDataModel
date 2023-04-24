SELECT  
DISTINCT SRD.RD_DATARQ
        ,RIGHT(SRD.RD_DATARQ,2)+'/'+LEFT(SRD.RD_DATARQ,4) RD_MESANO
        ,LEFT(SRD.RD_DATARQ,4)+'/'+RIGHT(SRD.RD_DATARQ,2) RD_ANOMES
        ,(
            CASE RIGHT(RD_DATARQ,2) 
             WHEN '01' THEN 'JAN'
             WHEN '02' THEN 'FEV'
             WHEN '03' THEN 'MAR'
             WHEN '04' THEN 'ABR'
             WHEN '05' THEN 'MAI'
             WHEN '06' THEN 'JUN'
             WHEN '07' THEN 'JUL'
             WHEN '08' THEN 'AGO'
             WHEN '09' THEN 'SET'
             WHEN '10' THEN 'OUT'
             WHEN '11' THEN 'NOV'
             WHEN '12' THEN 'DEZ'
             WHEN '13' THEN 'DEZ13'
            END + LEFT(RD_DATARQ,4)
         ) ALIASACM
   FROM SRD990 SRD
  WHERE SRD.RD_DATARQ BETWEEN !DATARQDE! AND !DATARQATE!