#More APIs! Example, ability to export certificate private key

# show same code on both pwsh6 and 7
$rsa = [System.Security.Cryptography.RSA]::Create(2048)

$dn = [X500DistinguishedName]::new('CN="bogus"')

$certReq = [System.Security.Cryptography.X509Certificates.CertificateRequest]::new(
  $dn,
  $rsa,
  [System.Security.Cryptography.HashAlgorithmName]::SHA256,
  [System.Security.Cryptography.RSASignaturePadding]::Pkcs1
)

$cert = $certReq.CreateSelfSigned([System.DateTimeOffset]::UtcNow, [System.DateTimeOffset]::UtcNow.AddYears(2))

$cert.ToString(1)

# now try to export private key
([System.Convert]::ToBase64String(
    $cert.PrivateKey.ExportRSAPrivateKey(),
    [System.Base64FormattingOptions]::InsertLineBreaks
  )
)