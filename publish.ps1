$message = Read-Host "Message"

if ($message -eq "") {
    Write-Host "Empty Message!"
}
else {
    git add . && git commit -m "$message" && git push
    Write-Host "Done"
}

timeout /t 5