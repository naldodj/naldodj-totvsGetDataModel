param( [string] $codModel)

function totvsGetDataModelPeriod {

    param(
            [parameter(Mandatory = $true)] [string] $codModel
        )

    function Get-IniFile {

        param(
            [parameter(Mandatory = $true)] [string] $filePath,
            [string] $anonymous = 'NoSection',
            [switch] $comments,
            [string] $commentsSectionsSuffix = '_',
            [string] $commentsKeyPrefix = 'Comment'
        )

        $ini = @{}
        switch -regex -file ($filePath) {
            "^\[(.+)\]$" {
                # Section
                $section = $matches[1]
                $ini[$section] = @{}
                $CommentCount = 0
                if ($comments) {
                    $commentsSection = $section + $commentsSectionsSuffix
                    $ini[$commentsSection] = @{}
                }
                continue
            }

            "^(;.*)$" {
                # Comment
                if ($comments) {
                    if (!($section)) {
                        $section = $anonymous
                        $ini[$section] = @{}
                    }
                    $value = $matches[1]
                    $CommentCount = $CommentCount + 1
                    $name = $commentsKeyPrefix + $CommentCount
                    $commentsSection = $section + $commentsSectionsSuffix
                    $ini[$commentsSection][$name] = $value
                }
                continue
            }

            "^(.+?)\s*=\s*(.*)$" {
                # Key
                if (!($section)) {
                    $section = $anonymous
                    $ini[$section] = @{}
                }
                $name, $value = $matches[1..2]
                $ini[$section][$name] = $value
                continue
            }
        }

        return $ini
    }

    $scriptName=$codModel
    if (-not $scriptName.ToLower().contains(".ps1")) { $scriptName+=".ps1" }

    $scriptIni=$scriptName.ToLower().Replace(".ps1",".ini")
    $scriptIni="..\cfg\$scriptIni"

    [System.Object]$ini=Get-IniFile $scriptIni

    [int]$RowspPageMax=[int]$ini.rest.RowspPageMax

    $Utf8NoBomEncoding=New-Object System.Text.UTF8Encoding $False

    $MC=Measure-Command {

        clear-host

        $Uri=$ini.PERIODOS_SRD.EndPoint
        $Auth=$ini.PERIODOS_SRD.Auth

        $codEmp=$ini.PERIODOS_SRD.codEmp
        $codModel=$ini.PERIODOS_SRD.codModel

        $minDatarq=$ini.PERIODOS_SRD.minDatarq
        $minDatarq=(get-date).AddMonths(-([int]$minDatarq))
        $minDatarq=($minDatarq.Year.ToString()+("{0:d2}" -f $minDatarq.Month))

        $maxDatarq=(get-date)
        $maxDatarq=($maxDatarq.Year.ToString()+("{0:d2}" -f $maxDatarq.Month))
        
        $fieldDATARQ=$ini.PERIODOS_SRD.fieldDATARQ

        $Filter="$fieldDATARQ BETWEEN '$minDatarq' AND '$maxDatarq'"

        $parModel='{"parameters":['

        $parModel+='['
        $parModel+='"!EMPRESA!"'
        $parModel+=','
        $parModel+='"'
        $parModel+=''''
        $parModel+=$codEmp
        $parModel+=''''
        $parModel+='"'
        $parModel+=']'

        $parModel+=','

        $parModel+='['
        $parModel+='"!DATARQDE!"'
        $parModel+=','
        $parModel+='"'
        $parModel+=''''
        $parModel+=$minDatarq
        $parModel+=''''
        $parModel+='"'
        $parModel+=']'

        $parModel+=','

        $parModel+='['
        $parModel+='"!DATARQATE!"'
        $parModel+=','
        $parModel+='"'
        $parModel+=''''
        $parModel+=$maxDatarq
        $parModel+=''''
        $parModel+='"'
        $parModel+=']'

        $parModel+=']}'

        $parModel=[Convert]::ToBase64String($Utf8NoBomEncoding::UTF8.GetBytes($parModel))

        [bool]$HasjsonServerdb=$false
        try {
             $jsonServerdb=$ini.jsonserver.db
             $HasjsonServerdb=($jsonServerdb -ne $null)
        }
        catch {
            $HasjsonServerdb=$false
        }
        
        [bool]$HasjsonServerHost=$false
        try {
             $jsonServerHost=$ini.jsonserver.Host
             $HasjsonServerHost=($jsonServerHost -ne $null)
        }
        catch {
            $HasjsonServerHost=$false
        }

        $msgProcess0=$codModel

        $ContentType="application/json;charset=utf-8"

        $PageNumber=1
        $RowspPage=999

        $headers=@{}
        $headers.Add("ServerHost","Connecti")
        $headers.Add("Authorization",$Auth)
        $headers.Add("tenantId",$codEmp)

        $Body=@{
            PageNumber=$PageNumber
            RowspPage=$RowspPage
            codModel=$codModel
            Filter=$Filter
            parModel=$parModel
        }

        $params = @{
            Uri=$Uri
            Headers=$headers
            Method="GET"
            ContentType=$ContentType
            Body=$Body
        }

        $resultPeriodosSRD=Invoke-RestMethod @params

        $Uri=$ini.rest.EndPoint
        $Auth=$ini.rest.Auth
        $codEmp=$ini.rest.codEmp
        $codModel=$ini.rest.codModel
        $msgProcess1=$codModel

        $jsonPath=$ini.rest.jsonPath
        if (-not $jsonPath.EndsWith("\"))
        {
            $jsonPath+="\"
        }
        $jsonPath+=$codEmp
        $jsonPath+="\"
        $jsonPath+=$codModel
        $jsonPath+="\"

        New-Item -ItemType Directory -Force -Path $jsonPath

        [int]$nPagenumber=0

        $Periodos=[System.Collections.ArrayList]@()
        foreach ($Periodo in $resultPeriodosSRD.table.items)
        {
            $PeriodoSRD=$Periodo.detail.items.codPeriodo
            if ($PeriodoSRD -ge $minDatarq)
            {
                $Periodos.add($PeriodoSRD)
            }
        }

        $Periodos=($Periodos|Sort-Object -Descending)

        foreach ($Periodo in $Periodos)
        {

            $PeriodoSRD=$Periodo

            $Filter="RD_DATARQ='$PeriodoSRD'"

            $parModel='{"parameters":['

            $parModel+='['
            $parModel+='"!EMPRESA!"'
            $parModel+=','
            $parModel+='"'
            $parModel+=''''
            $parModel+=$codEmp
            $parModel+=''''
            $parModel+='"'
            $parModel+=']'

            $parModel+=','

            $parModel+='['
            $parModel+='"!DATARQDE!"'
            $parModel+=','
            $parModel+='"'
            $parModel+=''''
            $parModel+=$PeriodoSRD
            $parModel+=''''
            $parModel+='"'
            $parModel+=']'

            $parModel+=','

            $parModel+='['
            $parModel+='"!DATARQATE!"'
            $parModel+=','
            $parModel+='"'
            $parModel+=''''
            $parModel+=$PeriodoSRD
            $parModel+=''''
            $parModel+='"'
            $parModel+=']'

            $parModel+=','

            $parModel+='['
            $parModel+='"!FILIALDE!"'
            $parModel+=','
            $parModel+='"'
            $parModel+=''''
            $parModel+=' '
            $parModel+=''''
            $parModel+='"'
            $parModel+=']'

            $parModel+=','

            $parModel+='['
            $parModel+='"!FILIALATE!"'
            $parModel+=','
            $parModel+='"'
            $parModel+=''''
            $parModel+='Z'
            $parModel+=''''
            $parModel+='"'
            $parModel+=']'

            $parModel+=','

            $parModel+='['
            $parModel+='"!CCDE!"'
            $parModel+=','
            $parModel+='"'
            $parModel+=''''
            $parModel+=' '
            $parModel+=''''
            $parModel+='"'
            $parModel+=']'

            $parModel+=','

            $parModel+='['
            $parModel+='"!CCATE!"'
            $parModel+=','
            $parModel+='"'
            $parModel+=''''
            $parModel+='Z'
            $parModel+=''''
            $parModel+='"'
            $parModel+=']'

            $parModel+=','

            $parModel+='['
            $parModel+='"!GRUPODE!"'
            $parModel+=','
            $parModel+='"'
            $parModel+=''''
            $parModel+=' '
            $parModel+=''''
            $parModel+='"'
            $parModel+=']'

            $parModel+=','

            $parModel+='['
            $parModel+='"!GRUPOATE!"'
            $parModel+=','
            $parModel+='"'
            $parModel+=''''
            $parModel+='Z'
            $parModel+=''''
            $parModel+='"'
            $parModel+=']'

            $parModel+=','

            $parModel+='['
            $parModel+='"!VERBADE!"'
            $parModel+=','
            $parModel+='"'
            $parModel+=''''
            $parModel+=' '
            $parModel+=''''
            $parModel+='"'
            $parModel+=']'

            $parModel+=','

            $parModel+='['
            $parModel+='"!VERBAATE!"'
            $parModel+=','
            $parModel+='"'
            $parModel+=''''
            $parModel+='Z'
            $parModel+=''''
            $parModel+='"'
            $parModel+=']'

            $parModel+=','

            $parModel+='['
            $parModel+='"!FUNCAODE!"'
            $parModel+=','
            $parModel+='"'
            $parModel+=''''
            $parModel+=' '
            $parModel+=''''
            $parModel+='"'
            $parModel+=']'

            $parModel+=','

            $parModel+='['
            $parModel+='"!FUNCAOATE!"'
            $parModel+=','
            $parModel+='"'
            $parModel+=''''
            $parModel+='Z'
            $parModel+=''''
            $parModel+='"'
            $parModel+=']'

            $parModel+=','

            $parModel+='['
            $parModel+='"!MATRICULADE!"'
            $parModel+=','
            $parModel+='"'
            $parModel+=''''
            $parModel+=' '
            $parModel+=''''
            $parModel+='"'
            $parModel+=']'

            $parModel+=','

            $parModel+='['
            $parModel+='"!MATRICULAATE!"'
            $parModel+=','
            $parModel+='"'
            $parModel+=''''
            $parModel+='Z'
            $parModel+=''''
            $parModel+='"'
            $parModel+=']'

            $parModel+=']}'

            $parModel=[Convert]::ToBase64String($Utf8NoBomEncoding::UTF8.GetBytes($parModel))

            $nPagenumber++
            $nPercent=[int](($nPagenumber/$resultPeriodosSRD.table.items.Length)*100)
            $nPercent=($nPercent,100 | Measure-Object -Min).Minimum

            $sPageNumber=("{0:d10}" -f $nPagenumber)
            $sTotalPages=("{0:d10}" -f $resultPeriodosSRD.table.items.Length)

            Write-Progress -id 0 `
                        -Activity "Processando [$sPageNumber]/[$sTotalPages)][$msgProcess0 :: $PeriodoSRD]" `
                        -PercentComplete "$nPercent" `
                        -Status ("Working["+($nPercent)+"]%")

            $jsonFile=$scriptName.ToLower().Replace(".ps1","")
            $jsonFile=$codEmp
            $jsonFile+="_"
            $jsonFile+=$codModel
            $jsonFile+="_"
            $jsonFile+=$PeriodoSRD

            $ContentType="application/json;charset=utf-8"

            $PageNumber=1
            $RowspPage=1

            $headers=@{}
            $headers.Add("ServerHost","Connecti")
            $headers.Add("Authorization",$Auth)
            $headers.Add("tenantId",$codEmp)

            $Body=@{
                PageNumber=$PageNumber
                RowspPage=$RowspPage
                codModel=$codModel
                Filter=$Filter
                parModel=$parModel
            }

            $params = @{
                Uri=$Uri
                Headers=$headers
                Method="GET"
                ContentType=$ContentType
                Body=$Body
            }

            $result=Invoke-RestMethod @params

            if ($result.TotalPages -ne $RowspPageMax)
            {

                $RowspPage=($result.TotalPages,$RowspPageMax | Measure-Object -Min).Minimum

                $Body=@{
                    PageNumber=$PageNumber
                    RowspPage=$RowspPage
                    codModel=$codModel
                    Filter=$Filter
                    parModel=$parModel
                }
                $params = @{
                    Uri=$Uri
                    Headers=$headers
                    Method="GET"
                    ContentType=$ContentType
                    Body=$Body
                }
                $result=Invoke-RestMethod @params
            }
            else
            {
                $hasNextPage=$result.hasNextPage
            }

            $removeItem=$jsonPath
            $removeItem+=$jsonFile
            $removeItem+="*"

            get-item $removeItem | remove-item -force

            $nRowCount=0

            do
            {

                if ($result.TotalPage -eq 0){
                    break
                }

                $nPercent=[int]((++$nRowCount/$result.TotalPages)*100)
                $nPercent=($nPercent,100 | Measure-Object -Min).Minimum

                $sRowCount=("{0:d10}" -f $nRowCount)
                $sPageNumber=("{0:d10}" -f $result.PageNumber)
                $sTotalPages=("{0:d10}" -f $result.TotalPages)

                Write-Progress -id 1 `
                            -Activity "Processando [$sRowCount]/[$sTotalPages)][$msgProcess1 :: $PeriodoSRD]" `
                            -PercentComplete "$nPercent" `
                            -Status ("Working["+($nPercent)+"]%")

                $OutFile=$jsonPath
                $OutFile+=$jsonFile
                $OutFile+="_"
                $OutFile+=$sPageNumber
                $OutFile+="_"
                $OutFile+=$sTotalPages
                $OutFile+=".json"

                $JsonResult=($result | ConvertTo-Json -depth 100 -Compress )

                [System.IO.File]::WriteAllLines($OutFile,$JsonResult,$Utf8NoBomEncoding)

                if ($HasjsonServerdb){

                    $OutFile=$OutFile.Replace($jsonPath,$jsonServerdb)
                    
                    $jsonServerdbEndPoint=$OutFile.Replace($jsonServerdb,"")

                    $jsonServerdbJSON='{"'
                    $jsonServerdbJSON+=$jsonServerdbEndPoint
                    $jsonServerdbJSON+='":['
                    $jsonServerdbJSON+='{'
                    $jsonServerdbJSON+='"id":0,'
                    $jsonServerdbJSON+='"data":'
                    $jsonServerdbJSON+=$JsonResult
                    $jsonServerdbJSON+='}'
                    $jsonServerdbJSON+=']'
                    $jsonServerdbJSON+='}'

                    [bool]$lExistOutFile=[System.IO.File]::Exists($OutFile)
                    if (($lExistOutFile)-and($HasjsonServerHost))
                    {
                        $params = @{
                            Uri=$jsonServerHost+$jsonServerdbEndPoint                        
                            Method="POST"
                            ContentType=$ContentType
                            Body=$jsonServerdbJSON
                        }
                        Invoke-RestMethod @params
                    } else {  
                        [System.IO.File]::WriteAllLines($OutFile,$jsonServerdbJSON,$Utf8NoBomEncoding)
                    }   

                }

                if ($PageNumber -eq $result.TotalPages){
                    break
                }

                $PageNumber=$result.NextPage

                $Body=@{
                    PageNumber=$PageNumber
                    RowspPage=$RowspPage
                    codModel=$codModel
                    Filter=$Filter
                    parModel=$parModel
                }

                $params=@{
                    Uri=$Uri
                    Headers=$headers
                    Method="GET"
                    ContentType=$ContentType
                    Body=$Body
                }

                $result=Invoke-RestMethod @params

                $hasNextPage=(($result.hasNextPage) -or ($PageNumber -eq $result.TotalPages))

                start-sleep -Seconds .05

            } while ($hasNextPage)

        }

    }
    $MC | Out-Null
    clear-host
}

totvsGetDataModelPeriod $codModel