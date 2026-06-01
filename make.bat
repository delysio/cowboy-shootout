@echo off
REM --- Konfiguracja ---
set SOURCE=shootout.asm
set OUTPUT=bin\shootout.xex
set MADS_PATH=mads\mads.exe

REM --- Czyszczenie starego pliku ---
if exist %OUTPUT% del %OUTPUT%

REM --- Kompilacja ---
echo Kompiluje plik %SOURCE%...
%MADS_PATH% %SOURCE% -o:%OUTPUT%

REM --- Sprawdzenie bledow ---
if errorlevel 1 goto error

REM --- Uruchomienie Altirry ---
echo Kompilacja zakonczona sukcesem. Uruchamiam Altirre...
REM Uzywamy /singleinstance, zeby nie otwierac 10 okien emulatora przy kazdej poprawce
"f:\!_emulacja\AtariXE\Emulators\Altirra-1.3\Altirra64.exe" "%OUTPUT%"
goto end

:error
echo.
echo !!! WYSTAPIL BLAD KOMPILACJI !!!
pause

:end