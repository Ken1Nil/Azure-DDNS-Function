# DDNS script for Azure DNS zones using Azure Function App

Host type: Powershell

View the code in /Source/DDNSFunctionScript/run.ps1

Handles multiple DNS zones (if you have it) in one ResourceGroup. Updates or Creates A Record with TTL 60.

## Authentication
APIKey and/or username+password

Note: Can have both in Application settings, APIKey validated first

In Azure set your Configuration - Application settings:
- APIKey = _your-apikey-in-cleartext_

and/or

- User = _username_
- Password = _password-in-cleartext_

## HTTP GET examples

- Using APIKey:

Using Base64 encoded APIKey in headers!

https://yourfunctionapp.azurewebsites.net/api/DDNSFunctionScript?hostname=recordname.yourdnszone.com&myip=127.0.0.1

Using username+password:

https://yourfunctionapp.azurewebsites.net/api/DDNSFunctionScript?user=youruser&password=base64encodedpassword&hostname=recordname.yourdnszone.com&myip=127.0.0.1

For APEX domains e.g "yourdnszone.com" use "@.yourdnszone.com"

https://yourfunctionapp.azurewebsites.net/api/DDNSFunctionScript?hostname=@.yourdnszone.com&myip=127.0.0.1

## DDNS Client setup:

If you are using a DDNS Client that can handle custom URL:s
https://yourfunctionapp.azurewebsites.net/api/DDNSFunctionScript?user=[USERNAME]&password=[PASSWORD]&hostname=[DOMAIN]&myip=[IP]

## Credits
This repo has added functionality from Graham Gold https://github.com/goldjg blogpost: https://www.cirriustech.co.uk/blog/create-dynamic-dns-azure-dns-pt2/
