param( [string] $codModel)

function totvsGetDataModelPeriodAcc {

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

        $MonthIni="01"
        $MonthFim="12"

        $Uri=$ini.PERIODOS_SRD.EndPoint
        $Auth=$ini.PERIODOS_SRD.Auth

        $codEmp=$ini.PERIODOS_SRD.codEmp
        $codModel=$ini.PERIODOS_SRD.codModel

        $minDatarq=$ini.PERIODOS_SRD.minDatarq
        $minDatarq=(get-date).AddYears(-([int]$minDatarq))
        $minDatarq=($minDatarq.Year.ToString()+("{0:d2}" -f $minDatarq.Month))

        $maxDatarq=(get-date)
        $maxDatarq=($maxDatarq.Year.ToString()+("{0:d2}" -f $maxDatarq.Month))

        $fieldDATARQ=$ini.PERIODOS_SRD.fieldDATARQ

        $Filter="$fieldDATARQ BETWEEN '$minDatarq' AND '$maxDatarq'"
        $Filter=[Convert]::ToBase64String($Utf8NoBomEncoding::UTF8.GetBytes($Filter))

        $parameters=@(
            ("!EMPRESA!","'$codEmp'"),
            ("!DATARQDE!","'$minDatarq'"),
            ("!DATARQATE!","'$maxDatarq'")
        )

        $parModel=@{
            parameters=$parameters
        }

        $parModel=($parModel | ConvertTo-Json -depth 100 -Compress)

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
            Filter64=$Filter
            parModel=$parModel
        }

        $params = @{
            Uri=$Uri
            Headers=$headers
            Method="GET"
            ContentType=$ContentType
            Body=$Body
            TimeoutSec=0
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
                if ($Periodos -notcontains ($PeriodoSRD.Substring(0,4)))
                {
                    $Periodos.add($PeriodoSRD.Substring(0,4))
                }
            }
        }

        $Periodos=($Periodos|Sort-Object -Descending)

        foreach ($Periodo in $Periodos)
        {

            $PeriodoSRD=$Periodo

            $Filter=""

            $parameters=@(
                ("!EMPRESA!","'$codEmp'"),
                ("!DATARQDE!","'$PeriodoSRD$MonthIni'"),
                ("!DATARQATE!","'$PeriodoSRD$MonthFim'"),
                ("!FILIALDE!","' '"),
                ("!FILIALATE!","'Z'"),
                ("!CCDE!","' '"),
                ("!CCATE!","'Z'"),
                ("!GRUPODE!","' '"),
                ("!GRUPOATE!","'Z'"),
                ("!VERBADE!","' '"),
                ("!VERBAATE!","'Z'"),
                ("!FUNCAODE!","' '"),
                ("!FUNCAOATE!","'Z'"),
                ("!MATRICULADE!","' '"),
                ("!MATRICULAATE!","'Z'")
            )

            $parModel=@{
                parameters=$parameters
            }

            $parModel=($parModel | ConvertTo-Json -depth 100 -Compress)

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
            $jsonFile+=$PeriodoSRD.Substring(0,4)

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
                Filter64=$Filter
                parModel=$parModel
            }

            $params = @{
                Uri=$Uri
                Headers=$headers
                Method="GET"
                ContentType=$ContentType
                Body=$Body
                TimeoutSec=0
            }

            $result=Invoke-RestMethod @params

            if ($result.TotalPages -ne $RowspPageMax)
            {

                $RowspPage=($result.TotalPages,$RowspPageMax | Measure-Object -Min).Minimum

                $Body=@{
                    PageNumber=$PageNumber
                    RowspPage=$RowspPage
                    codModel=$codModel
                    Filter64=$Filter
                    parModel=$parModel
                }
                $params = @{
                    Uri=$Uri
                    Headers=$headers
                    Method="GET"
                    ContentType=$ContentType
                    Body=$Body
                    TimeoutSec=0
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

                if ($OutFile.Contains("__.json")){
                    break
                }

                $JsonResult=($result | ConvertTo-Json -depth 100 -Compress )

                [System.IO.File]::WriteAllLines($OutFile,$JsonResult,$Utf8NoBomEncoding)

                if ($HasjsonServerdb){

                    $OutFile=$OutFile.Replace($jsonPath,$jsonServerdb)

                    $jsonServerdbEndPoint=$OutFile.Replace($jsonServerdb,"")

                    $jsonServerdbJSON=@{
                        $jsonServerdbEndPoint=@(
                            @{
                                id=0
                                data=$result
                            }
                        )
                    }

                    $jsonServerdbJSON=($jsonServerdbJSON | ConvertTo-Json -depth 100 -Compress)

                    [bool]$lExistOutFile=[System.IO.File]::Exists($OutFile)
                    if (($lExistOutFile)-and($HasjsonServerHost))
                    {
                        $params = @{
                            Uri=$jsonServerHost+$jsonServerdbEndPoint
                            Method="POST"
                            ContentType=$ContentType
                            Body=$jsonServerdbJSON
                            TimeoutSec=0
                        }
                        try {
                            Invoke-RestMethod @params
                        } catch {
                            Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__ 
                            Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription
                        }
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
                    Filter64=$Filter
                    parModel=$parModel
                }

                $params=@{
                    Uri=$Uri
                    Headers=$headers
                    Method="GET"
                    ContentType=$ContentType
                    Body=$Body
                    TimeoutSec=0
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

totvsGetDataModelPeriodAcc $codModel