# ConvertFrom-Json

#round trip not ok in pwsh 6
'[1,2]' | ConvertFrom-Json | Get-Member
'[1]' | ConvertFrom-Json | ConvertTo-Json

#new in pwsh 7:
'[1,2]' | ConvertFrom-Json -NoEnumerate | Get-Member
'[1]' | ConvertFrom-Json -NoEnumerate | ConvertTo-Json


# other things added in pwsh 6:
'{"event": "DuPSUG"}' | ConvertFrom-Json
'{"event": "DuPSUG"}' | ConvertFrom-Json -AsHashtable

# added in pwsh 6.2:

ConvertFrom-Json -Depth 2048

# ConvertTo-Json, nothing new in 7 but don't forget!

#added in pwsh 6.x:

# enumasstrings
enum bla {
  bla1 = 1
}

@{
  bla = [bla]::bla1
} | ConvertTo-Json

@{
  bla = [bla]::bla1
} | ConvertTo-Json -EnumsAsStrings

# asarray
1 | ConvertTo-Json -AsArray

# escapehandling
"bla`nbla2" | ConvertTo-Json -EscapeHandling EscapeNonAscii
'https://someurl.com?query="value with spaces"' | ConvertTo-Json -EscapeHandling EscapeHtml
