# Download all github gists for specified user
$gistUser = "jjgroenendijk"
$gistDir = ".\gists"
$gists = Invoke-RestMethod -Uri "https://api.github.com/users/$gistUser/gists" -Method Get

# download all gists to folder $gistDir
foreach ($gist in $gists) {

}