@ECHO OFF

:: устанавливаем целевую архитектуру
SET GOARCH=amd64
:: отключаем зависимость от libc
SET CGO_ENABLED=0

:: устанавливаем целевую ОС и собираем
SET GOOS=windows
go build -o client.exe main.go

:: устанавливаем целевую ОС и собираем
SET GOOS=linux
go build -o client.bin main.go