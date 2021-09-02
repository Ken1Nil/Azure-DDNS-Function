using namespace System.Net

param($Request, $TriggerMetadata)
# APIKey in header, Username or Password in Query exist
if (!$Request.headers.APIKey -And !$Request.Query.user -And !$Request.Query.password) {
    write-host "No API key, username or password"
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::Unauthorized
            Body       = "401 - Authentication failed"
        })
    exit
}

if($Request.headers.APIKey) {
    write-host "Using APIKey for Authentication"
    # Checks that it's sent with Base64Encoded
    $Base64APIKey = $Request.headers.APIKey -split " " | select-object -last 1
    $APIKey = [Text.Encoding]::Utf8.GetString([Convert]::FromBase64String($Base64APIKey)) -split ":" | select-object -last 1
    # APIKey validate
    if ($APIKey -ne $env:APIKey) {
        write-host "Invalid API key"
        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode = [HttpStatusCode]::Unauthorized
                Body       = "401 - API token is invalid."
            })
        exit
    }
    else {
        write-host "APIKey verified"
    }
    
}
elseif ($Request.Query.user -And $Request.Query.password) {
    write-host "Using user and password for Authentication"
    # Checks that it's sent with Base64Encoded
    $Base64password = $Request.Query.password
    $Password = [Text.Encoding]::Utf8.GetString([Convert]::FromBase64String($Base64password)) -split ":" | select-object -last 1
    $User = $Request.Query.user
    # Password validate
    if ($Password -ne $env:Password) {
        write-host "Invalid Password"
        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode = [HttpStatusCode]::Unauthorized
                Body       = "401 - Password is invalid."
            })
        exit
    }
    else {
        write-host "Password verified"
    }
    if ($User -ne $env:User) {
        write-host "Invalid User: " $User
        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode = [HttpStatusCode]::Unauthorized
                Body       = "401 - User is invalid."
            })
        exit
    }else {
        write-host "User verified"
    }
}

# Validate that two '.' is in hostname, for APEX use '@.domain.com'
if ($Request.Query.hostname.Length - $Request.Query.hostname.replace(".","").Length -ne 2) {
    write-host "hostname input does not contain two '.' please use hostname=@.domain.com in query for APEX domains"
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode = [HttpStatusCode]::BadRequest
                Body       = "400 - hostname format wrong"
            })
    exit
}
# Validate ip
$validIP = $Request.Query.myip -as [System.Net.IPAddress] -as [Bool]
if (!$validIP) {
    write-host "IP cant be cast to the IPv4 type. IP Address format wrong"
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode = [HttpStatusCode]::BadRequest
                Body       = "400 - myip format wrong"
            })
    exit
}
# Gets first Azure DNS Zone
$AutoDetect = (get-azresource -ResourceType "Microsoft.Network/dnszones")
If (@($Autodetect.Name).Count -eq 1) {
    # Only one dnszone found, easy just use it
    write-host "Using Autodetect. Using ZoneName: " $Autodetect.name " ResourceGroupName: " $AutoDetect.ResourceGroupName
    $ZoneName = $Autodetect.Name
    $ResourceGroupName = $AutoDetect.ResourceGroupName
}
else {
    #Infer DNS Zone Name from hostname in query, remove first part "sub."
    $ZoneName = $Request.Query.hostname.split('.') | select-object -skip 1
    $ZoneName = $ZoneName -join "." 
    
    #Takes the ResourceGroupName "myResources" from found DNS Zone Name "sub.contoso.com"    
    $ResourceGroupName = ($AutoDetect | Where-Object {$_.Name -eq $ZoneName} | Select -ExpandProperty "ResourceGroupName")    
}

#Gets the Record to update "sub" and new IP
$Domain = $Request.Query.hostname.split('.') | select-object -first 1
$NewIP = $Request.Query.myip
write-output "ResourceGrop:" $ResourceGroupName "ZoneName:" $ZoneName "RecordName:" $Domain "IP:" $NewIP
write-host "Checking record and creating if required."
$ExistingRecord = Get-AzDnsRecordSet -ResourceGroupName $ResourceGroupName -ZoneName $ZoneName -Name $Domain -RecordType A -ErrorAction SilentlyContinue
if (!$ExistingRecord) {
    write-host "Creating new record for $Domain.$ZoneName"
    New-AzDnsRecordSet -name $Domain -Zonename $ZoneName -ResourceGroupName $ResourceGroupName -RecordType A -Ttl 60 -DnsRecords (New-AzDnsRecordConfig -Ipv4Address $NewIP)
    Push-OutputBinding -Name Response -Value (  [HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::OK
            Body       = "Creating new record for $Domain.$ZoneName, good $NewIP"
        })
    exit 
}
else {
    if ($ExistingRecord.Records[-1].Ipv4Address -ne $NewIP) { 
        write-host "Updating record for $Domain.$ZoneName - new IP is $NewIP"
        $ExistingRecord.Records[-1].Ipv4Address = $NewIP
        Set-AzDnsRecordSet -RecordSet $ExistingRecord
        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode = [HttpStatusCode]::OK
                Body       = "Updating record for $Domain.$ZoneName - new IP is $NewIP"
            })
    }
    else {
        write-host "No Change - $Domain.$ZoneName IP is still $NewIP"
        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode = [HttpStatusCode]::OK
                Body       = "No Change - $Domain.$ZoneName IP is still $NewIP"
            })
    }
    exit
}