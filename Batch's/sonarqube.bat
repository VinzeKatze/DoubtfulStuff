@echo off
echo.
SET timeoutvar=0

:: ����� ��⭨� �蠥� ���쬠 ���㬠��� �஡����:
::     1) ��� ���� 室��� �� ������ � ���᪠� docker-compose.yaml �⮡� 
::        ����᪠�� ����室��� ��� �ࢨ�.
::     2) ����� � �ய�ᠫ ���஡�⭨�� � ��������� ����᪠ ��� �ࢨᮢ � PATH,
::        � �⠫ ���뢠�� ������� ᠬ docker...
::
:: ��� ���������� �� 㤠�� ������� ���몠�� ������ cmd �ਯ�� � ������� +/-
:: 㭨���ᠫ�� ���⮩ �ਯ� ��� ����᪠. 
:: -----------------------------------------------------------------------------
:: ��ࠬ���:
::
:: dockerpath  -  ���� �� ��४�ਨ � "docker desktop.exe"
:: mytimoutset -  �६� ����� ��᫥ ������� ����᪠ �����
:: -----------------------------------------------------------------------------
:: ����� �ਯ� � ��ࠬ��ࠬ� �ਢ���� ���� � �⮡ࠦ���� continfo
:: ��� ��ࠬ��஢ - �����業�� �����
:: -----------------------------------------------------------------------------
:: �.�.: ��� �⮡ࠦ���� ��ਫ���, ����뢠����, �㦭� ����஢�� Cyrillic CP 866.

SET dockerpath=C:\Program Files\Docker\Docker\
SET mytimoutset=5


:: �����, ����� � ��� ������ ��। ����᪮�
echo �����: sonarqube:sonarqube
echo ���� : 9000
echo.


:: �஢�ઠ ��㬥�⮢
if "%1" NEQ "" ( 
	echo ...
	echo.
	echo ��� ���� �ࢨ� �ॡ���� �������� �ਯ� ��� ��ࠬ��஢.
	echo.
	GOTO:EOF 
)

:: �஢�ઠ, ����饭 �� ����� �����
for /F %%i in ('tasklist /FI "IMAGENAME eq docker.exe" ^| find /C "docker.exe"') do (
	if "%%i" NEQ "0" GOTO:DockerWait
)

:: �᫨ �� ����饭, � �����
:DockerRun
SET /P dockerask="��� �� �ᥬ� docker �� ����饭. ��������? [Y(��)/N(���)]? "
IF /I "%dockerask%" == "y" (
	cd /D "%dockerpath%"
	start "" "docker desktop.exe"
	SET timeoutvar=%mytimoutset%
	GOTO:DockerWait
	)
IF /I "%dockerask%" == "n" ( GOTO:EOF 
) ELSE ( GOTO:DockerRun )


:: �������� ����᪠ �����. ����祭�, �� �� ����� ����� �⠭������ +/- ࠡ��ᯮᮡ��, 
:: ����� ������ 5 ����ᮢ Docker Desktop.exe. � ⠩���⮬ ��᫥ ����᪠  �� ࠡ�⠥�
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

:: ����� ���⥩���
cd /D D:\Programming\Docker\SonarQube\ && wsl -d docker-desktop sysctl -w vm.max_map_count=262144 && docker-compose up