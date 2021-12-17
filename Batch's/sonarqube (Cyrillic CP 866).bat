@echo off
echo.
SET timeoutvar=0

:: „ ­­ë© ¡ â­¨ª à¥è ¥â ¢¥áì¬  ­ ¤ã¬ ­­ë¥ ¯à®¡«¥¬ë:
::     1) Œ­¥ «¥­ì å®¤¨âì ¯® ¯ ¯ª ¬ ¢ ¯®¨áª å docker-compose.yaml çâ®¡ë 
::        § ¯ãáª âì ­¥®¡å®¤¨¬ë© ¬­¥ á¥à¢¨á.
::     2) Š®£¤  ï ¯à®¯¨á « ¬¨ªà®¡ â­¨ª¨ á ª®¬ ­¤ ¬¨ § ¯ãáª  íâ¨å á¥à¢¨á®¢ ¢ PATH,
::        ï áâ « § ¡ë¢ âì ¢ª«îç¨âì á ¬ docker...
::
:: Œ­¥ ¯®ª § «®áì íâ® ã¤ ç­ë¬ ¯®¢®¤®¬ ¯®âëª âì ¯ «ª®© cmd áªà¨¯âë ¨ ­ ¯¨á âì +/-
:: ã­¨¢¥àá «ì­ë© ¯à®áâ®© áªà¨¯â ¤«ï § ¯ãáª . 
:: -----------------------------------------------------------------------------
::  à ¬¥âë:
::
:: dockerpath  -  ¯ãâì ¤® ¤¨à¥ªâ®à¨¨ á "docker desktop.exe"
:: mytimoutset -  ¢à¥¬ï ¯à®áâ®ï ¯®á«¥ ¯®«­®£® § ¯ãáª  ¤®ª¥à 
:: -----------------------------------------------------------------------------
:: ‡ ¯ãáª áªà¨¯â  á ¯ à ¬¥âà ¬¨ ¯à¨¢®¤¨â «¨èì ª ®â®¡à ¦¥­¨î continfo
:: ¥§ ¯ à ¬¥âà®¢ - ¯®«­®æ¥­­ë© § ¯ãáª
:: -----------------------------------------------------------------------------
:: ‡.›.: „«ï ®â®¡à ¦¥­¨ï ª¨à¨«¨æë, ®ª §ë¢ ¥âáï, ­ã¦­  ª®¤¨à®¢ª  Cyrillic CP 866.

SET dockerpath=C:\Program Files\Docker\Docker\
SET mytimoutset=5


:: ’¥ªáâ, ª®â®àë© ï å®çã ¢¨¤¥âì ¯¥à¥¤ § ¯ãáª®¬
echo €¤¬¨­: sonarqube:sonarqube
echo ®àâ : 9000
echo.


:: à®¢¥àª   à£ã¬¥­â®¢
if "%1" NEQ "" ( 
	echo ...
	echo.
	echo „«ï áâ àâ  á¥à¢¨á  âà¥¡ã¥âáï § ¯ãáâ¨âì áªà¨¯â ¡¥§ ¯ à ¬¥âà®¢.
	echo.
	GOTO:EOF 
)

:: à®¢¥àª , § ¯ãé¥­ «¨ ¢®®¡é¥ ¤®ª¥à
for /F %%i in ('tasklist /FI "IMAGENAME eq docker.exe" ^| find /C "docker.exe"') do (
	if "%%i" NEQ "0" GOTO:DockerWait
)

:: …á«¨ ­¥ § ¯ãé¥­, â® ¢®¯à®á
:DockerRun
SET /P dockerask="‘ã¤ï ¯® ¢á¥¬ã docker ­¥ § ¯ãé¥­. ‡ ¯ãáâ¨âì? [Y(¤ )/N(­¥â)]? "
IF /I "%dockerask%" == "y" (
	cd /D "%dockerpath%"
	start "" "docker desktop.exe"
	SET timeoutvar=%mytimoutset%
	GOTO:DockerWait
	)
IF /I "%dockerask%" == "n" ( GOTO:EOF 
) ELSE ( GOTO:DockerRun )


:: Ž¦¨¤ ­¨¥ § ¯ãáª  ¤®ª¥à . ‡ ¬¥ç¥­®, çâ® ­  ¢¨­¤¥ ¤®ª¥à áâ ­®¢¨âáï +/- à ¡®â®á¯®á®¡¥­, 
:: ª®£¤  ¯®ï¢«ï¥âáï 5 ¯à®æ¥áá®¢ Docker Desktop.exe. ‘ â ©¬ ãâ®¬ ¯®á«¥ § ¯ãáª   ¢á¥ à ¡®â ¥â
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

:: ‡ ¯ãáª ª®­â¥©­¥à 
cd /D D:\Programming\Docker\SonarQube\ && wsl -d docker-desktop sysctl -w vm.max_map_count=262144 && docker-compose up
