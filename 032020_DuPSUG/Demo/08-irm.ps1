#New in pwsh 7:

Invoke-RestMethod http://example.com/notfound

Invoke-RestMethod http://example.com/notfound -SkipHttpErrorCheck -StatusCodeVariable stat -SessionVariable ses

<#
  Added parameters in pwsh 6:

  - AllowUnencryptedAuthentication
  - Authentication
  - CustomMethod
  - FollowRelLink
  - PreserveAuthorizationOnRedirect
  - Proxy
  - ResponseHeadersVariable
  - SkipCertificateCheck
  - SkipHeaderValidation
  - SslProtocol

  Added parameters in pwsh 6.1:

  - Form
  - Resume
#>