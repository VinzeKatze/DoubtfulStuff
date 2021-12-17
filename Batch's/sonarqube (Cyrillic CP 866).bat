@echo off
echo.
SET timeoutvar=0

:: Данный батник решает весьма надуманные проблемы:
::     1) Мне лень ходить по папкам в поисках docker-compose.yaml чтобы 
::        запускать необходимый мне сервис.
::     2) Когда я прописал микробатники с командами запуска этих сервисов в PATH,
::        я стал забывать включить сам docker...
::
:: Мне показалось это удачным поводом потыкать палкой cmd скрипты и написать +/-
:: универсальный простой скрипт для запуска. 
:: -----------------------------------------------------------------------------
:: Параметы:
::
:: dockerpath  -  путь до директории с "docker desktop.exe"
:: mytimoutset -  время простоя после полного запуска докера
:: -----------------------------------------------------------------------------
:: Запуск скрипта с параметрами приводит лишь к отображению continfo
:: Без параметров - полноценный запуск
:: -----------------------------------------------------------------------------
:: З.Ы.: Для отображения кирилицы, оказывается, нужна кодировка Cyrillic CP 866.

SET dockerpath=C:\Program Files\Docker\Docker\
SET mytimoutset=5


:: Текст, который я хочу видеть перед запуском
echo Админ: sonarqube:sonarqube
echo Порт : 9000
echo.


:: Проверка аргументов
if "%1" NEQ "" ( 
	echo ...
	echo.
	echo Для старта сервиса требуется запустить скрипт без параметров.
	echo.
	GOTO:EOF 
)

:: Проверка, запущен ли вообще докер
for /F %%i in ('tasklist /FI "IMAGENAME eq docker.exe" ^| find /C "docker.exe"') do (
	if "%%i" NEQ "0" GOTO:DockerWait
)

:: Если не запущен, то вопрос
:DockerRun
SET /P dockerask="Судя по всему docker не запущен. Запустить? [Y(да)/N(нет)]? "
IF /I "%dockerask%" == "y" (
	cd /D "%dockerpath%"
	start "" "docker desktop.exe"
	SET timeoutvar=%mytimoutset%
	GOTO:DockerWait
	)
IF /I "%dockerask%" == "n" ( GOTO:EOF 
) ELSE ( GOTO:DockerRun )


:: Ожидание запуска докера. Замечено, что на винде докер становится +/- работоспособен, 
:: когда появляется 5 процессов Docker Desktop.exe. С таймаутом после запуска  все работает
:DockerWait
for /F %%i in ('tasklist /FI "IMAGENAME eq Docker Desktop.exe" ^| find /C "Docker Desktop.exe"') do (
	if "%%i" LSS "5" (
		echo ...
        timeout %mytimoutset% /nobreak > nul
		GOTO:DockerWait
    ) ELSE ( 
		if %timeoutvar% NEQ 0 echo ...
		timeout %timeoutvar% /nobreak > nul 
		)
)

:: Запуск контейнера
cd /D D:\Programming\Docker\SonarQube\ && wsl -d docker-desktop sysctl -w vm.max_map_count=262144 && docker-compose up