@ECHO OFF

:: устанавливаем целевую архитектуру
SET GOARCH=amd64
:: отключаем зависимость от libc
SET CGO_ENABLED=0

:: устанавливаем целевую ОС и собираем
SET GOOS=windows
go build -o server.exe main.go

:: устанавливаем целевую ОС и собираем
SET GOOS=linux
go build -o server.bin main.go