$message = Read-Host "Message"

if ($message -eq "") {
    Write-Host "Empty Message! "
    return
}

git add . && git commit -m "$message" && git push