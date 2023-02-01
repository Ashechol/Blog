@echo off
set /p message=input message: 

if "%message%"=="" (
    echo empty message!
    goto end
)

git add . && git commit -m "%message%" && git push

:end