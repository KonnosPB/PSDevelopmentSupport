<#
.SYNOPSIS
This function is used to make web requests to a specified Uri with a specific HTTP method.

.DESCRIPTION
The Invoke-DevSuiteWebRequest function is a wrapper for the Invoke-WebRequest cmdlet in PowerShell. It adds additional functionality such as bearer token authorization, content type specification, error handling, and logging. This function will throw an exception if the HTTP response status code is not in the range 200-299, unless the SkipErrorHandling switch is specified.

.PARAMETER Uri
This parameter is mandatory. It specifies the Uri to which the web request should be made.

.PARAMETER Method
This parameter is mandatory. It specifies the HTTP method (GET, POST, PATCH) for the web request.

.PARAMETER Body
This parameter is optional. It specifies the body of the web request, if applicable.

.PARAMETER ContentType
This parameter is optional, with a default value of 'application/json'. It specifies the content type of the web request body.

.PARAMETER SkipErrorHandling
This parameter is optional. If specified, the function will not throw an exception if the HTTP response status code is not in the range 200-299.

.EXAMPLE
Invoke-DevSuiteWebRequest -Uri "http://example.com" -Method "GET"

This example makes a GET request to http://example.com.

.EXAMPLE
Invoke-DevSuiteWebRequest -Uri "http://example.com" -Method "POST" -Body @{name="example"}

This example makes a POST request to http://example.com with a JSON body containing {"name": "example"}.
#>
function Invoke-DevSuiteWebRequest {
    Param (
        [Parameter(Mandatory = $true)]
        [string] $Uri,      
        [Parameter(Mandatory = $true)]
        [ValidateSet("GET", "POST", "PATCH")]
        [string] $Method,      
        [Parameter(Mandatory = $false)]
        [object] $Body,
        [Parameter(Mandatory = $false)]
        [string] $ContentType = 'application/json',
        [Parameter(Mandatory = $false)]
        [switch] $SkipErrorHandling        
    )

    $bearerToken = Get-DevSuiteBearerToken

    $authHeaders = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $authHeaders.Add("Authorization", $bearerToken)

    $callingCommandFile = Split-Path $MyInvocation.PSCommandPath -Leaf | ForEach-Object { $_ -replace '\.[^.]+$', '' }

    if ($Body) {
        $authHeaders.Add("Content-Type", $ContentType)
        Write-Host "$callingCommandFile -Uri $Uri -Method $Method -Body $Body" -NoNewline  
        $script:result = Invoke-WebRequest -Uri $Uri -Method $Method -Headers $authHeaders -Body $Body -SkipHttpErrorCheck 
    }
    else {
        Write-Host "$callingCommandFile -Uri $Uri -Method $Method" -NoNewline  
        $script:result = Invoke-WebRequest -Uri $Uri -Method $Method -Headers $authHeaders -SkipHttpErrorCheck 
    }      
    
    if ($script:result.StatusCode -ge 200 -and $script:result.StatusCode -lt 300) {
        Write-Host " ✅"
        return($script:result);
    }
    else {
        Write-Host " ❌"
        if (!$SkipErrorHandling) {
            throw "$($script:result.StatusCode) $($script:result.StatusDescription)" 
        }
    }
}
Export-ModuleMember -Function Invoke-DevSuiteWebRequest