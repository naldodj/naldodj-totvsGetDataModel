param( [string] $codModel)

function totvsGetDataModel {

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

        $Uri=$ini.rest.EndPoint
        $Auth=$ini.rest.Auth
        $codEmp=$ini.rest.codEmp
        $codModel=$ini.rest.codModel

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

        $jsonPath=$ini.rest.jsonPath
        if (-not $jsonPath.EndsWith("\"))
        {
            $jsonPath+="\"
        }
        $jsonPath+=$codEmp
        $jsonPath+="\"
        $jsonPath+=$codModel
        $jsonPath+="\"

        $jsonFile=$scriptName.ToLower().Replace(".ps1","")
        $jsonFile=$codEmp
        $jsonFile+="_"
        $jsonFile+=$codModel

        New-Item -ItemType Directory -Force -Path $jsonPath

        $ContentType="application/json;charset=utf-8"

        $PageNumber=1
        $RowspPage=1

        $headers=@{}
        $headers.Add("ServerHost","Connecti")
        $headers.Add("Authorization",$Auth)
        $headers.Add("tenantId",$codEmp)

        $parameters=@(
            ("!EMPRESA!","'$codEmp'"),
            ("!DATARQDE!","' '"),
            ("!DATARQATE!","'Z'"),
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
        
        $parModel=($parModel | ConvertTo-Json)

        $parModel=[Convert]::ToBase64String($Utf8NoBomEncoding::UTF8.GetBytes($parModel))

        $Body=@{
            PageNumber=$PageNumber
            RowspPage=$RowspPage
            codModel=$codModel
            parmodel=$parModel
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
                parmodel=$parModel
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

        do
        {

            if ($result.TotalPage -eq 0){
                break
            }

            $nPercent=[int](($result.PageNumber/$result.TotalPages)*100)
            $nPercent=($nPercent,100 | Measure-Object -Min).Minimum

            $sPageNumber=("{0:d10}" -f $result.PageNumber)
            $sTotalPages=("{0:d10}" -f $result.TotalPages)

            Write-Progress -id 0 `
                           -Activity "Processando [$sPageNumber]/[$sTotalPages)][$codModel]" `
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
                parmodel=$parModel
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

        } while ($hasNextPage)

    }
    $MC | Out-Null
    clear-host
}

totvsGetDataModel $codModel
