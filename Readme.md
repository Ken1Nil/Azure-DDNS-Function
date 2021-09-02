# DDNS script for Azure DNS zones using Azure Function App

Host type: Powershell

View the code in /Source/DDNSFunctionScript/run.ps1

Handles multiple DNS zones (if you have it) in one ResourceGroup

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




_This repo has added functionality from Graham Gold https://github.com/goldjg blogpost: https://www.cirriustech.co.uk/blog/create-dynamic-dns-azure-dns-pt2/_
