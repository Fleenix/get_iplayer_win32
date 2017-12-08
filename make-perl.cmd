@echo off
REM Build script for get_iplayer Perl support files
setlocal EnableDelayedExpansion
REM show help if requested
echo.%1 | find "?" >NUL
if not ERRORLEVEL 1 goto usage
REM script location
set CMDNAME=%~n0
set CMDDIR=%~dp0
if #%CMDDIR:~-1%# == #\# set CMDDIR=%CMDDIR:~0,-1%
REM determine parent directory
for %%D in (%CMDDIR%\..) do (
	set BASEDIR=%%~fD
)
if #%BASEDIR:~-1%# == #\# set BASEDIR=%BASEDIR:~0,-1%
REM Perl build dir
set PERLDIR=%CMDDIR%\build\perl
if not exist "%PERLDIR%" (
	md "%PERLDIR%"
)
REM init logfile
set LOG=%PERLDIR%\%CMDNAME%.log
echo Logging to file: %LOG%
echo %* > "%LOG%"
call :log START %CMDNAME% %date% %time%
REM process get_iplayer version
set ARG1=%1
if "%ARG1%"=="" (
	call :log ERROR: get_iplayer version missing
	goto die
)
if "%ARG1:~0,1%"=="/" (
	call :log ERROR: get_iplayer version cannot be flag parameter
	goto die
)
REM process setup build number
set ARG2=%2
if "%ARG2%"=="" (
	call :log ERROR: setup build number missing
	goto die
)
if "%ARG2:~0,1%"=="/" (
	call :log ERROR: setup build number cannot be flag parameter
	goto die
)
set GIPVER=%ARG1%
set COIVER=%ARG1%.%ARG2%
call :log get_iplayer version: %GIPVER%
call :log setup version: %COIVER%
REM get_iplayer build dir
set GIPDIR=%CMDDIR%\build\get_iplayer
REM get_iplayer files dir
set COIDIR=%GIPDIR%\get_iplayer-%COIVER%
if not exist "%COIDIR%" (
	call :log ERROR: Cannot find %COIDIR%
	goto die
)
REM assume use of portable Strawberry Perl
set PERLEXE=none
for /f "usebackq" %%A in (`perl -e "print $^X;"`) do (
	set PERLEXE=%%A
)
if "%PERLEXE%" == "none" (
	call :log ERROR: Perl executable not discovered
	goto die
)
if not exist "%PERLEXE%" (
	call :log ERROR: Perl executable not found: %PERLEXE%
	goto die
)
set PERLDIST=%PERLEXE:\perl\bin\perl.exe=%
if not exist "%PERLDIST%" (
	call :log ERROR: Perl installation not found: %PERLDIST%
	goto die
)
call :log Perl installation: %PERLDIST%
REM determine Perl version
set PERLVER=0.0.0
for /f "usebackq tokens=1-3 delims=v." %%A in (`perl -e "print $^V;"`) do (
	set PERLVER=%%A.%%B.%%C
)
if "%PERLVER%"=="0.0.0" (
	call :log ERROR: Could not determine Perl version
	goto die
)
call :log Perl version: %PERLVER%
REM set PAR file name
set PARPFX=perl-%PERLVER%
REM PAR file in Perl build dir
set PARPAR=%PERLDIR%\%PARPFX%.par
if exist "%PARPAR%" (
	del "%PARPAR%"
)
REM PAR::Packer setup
set PP=pp.bat
REM force Encode::Byte into PAR
set PPMODS=%PPMODS% -M Encode::Byte
REM force XML modules into PAR
set PPMODS=%PPMODS% -M XML::LibXML -M XML::LibXML::SAX -M XML::LibXML::SAX::Parser -M XML::SAX::PurePerl -M XML::SAX::Expat -M XML::Parser
REM force JSON modules into PAR
set PPMODS=%PPMODS% -M JSON -M JSON::XS -M JSON::PP
REM force Mojolicious into PAR
set PPMODS=%PPMODS% -M Mojolicious
call :log Running pp...
REM run pp
call "%PP%" %PPMODS% -B -p -o "%PARPAR%" "%COIDIR%\get_iplayer" "%COIDIR%\get_iplayer.cgi" >> "%LOG%" 2>&1
REM check result
if %ERRORLEVEL% neq 0 (
	call :log ERROR: %PP% failed
	goto die
)
call :log ...Finished
REM make sure that PAR file is available
if not exist "%PARPAR%" (
	call :log ERROR: Cannot find %PARPAR%
	goto die
)
REM create clean output dir
for %%X in (%PARPAR%) do (
	set PARDIR=%PERLDIR%\%%~nX
)
if exist "%PARDIR%" (
	rd /q /s "%PARDIR%" >> "%LOG%" 2>&1
)
md "%PARDIR%" >> "%LOG%" 2>&1
call :log Perl support files: %PARDIR%
REM location of 7-Zip utility
set P7ZIP=%BASEDIR%\7-Zip\7z.exe
REM unpack lib dir from PAR
call :log Unpacking Perl library...
"%P7ZIP%" x "%PARPAR%" -o"%PARDIR%" -aoa
call :log ...Finished
REM copy additional files from Strawberry Perl
call :log Copying Perl support files...
xcopy "%PERLDIST%\licenses\perl\*.*" "%PARDIR%\licenses" /e /i /r /y >> "%LOG%" 2>&1
xcopy "%PERLDIST%\perl\lib\unicore\*.*" "%PARDIR%\lib\unicore" /e /i /r /y >> "%LOG%" 2>&1
copy /y "%PERLDIST%\perl\lib\utf8_heavy.pl" "%PARDIR%\lib" >> "%LOG%" 2>&1
copy /y "%PERLDIST%\perl\bin\*.dll" "%PARDIR%" >> "%LOG%" 2>&1
copy /y "%PERLDIST%\perl\bin\perl.exe" "%PARDIR%" >> "%LOG%" 2>&1
copy /y "%PERLDIST%\c\bin\libexpat*.dll" "%PARDIR%" >> "%LOG%" 2>&1
copy /y "%PERLDIST%\c\bin\libiconv*.dll" "%PARDIR%" >> "%LOG%" 2>&1
copy /y "%PERLDIST%\c\bin\libxml2*.dll" "%PARDIR%" >> "%LOG%" 2>&1
copy /y "%PERLDIST%\c\bin\zlib*.dll" "%PARDIR%" >> "%LOG%" 2>&1
copy /y "%PERLDIST%\c\bin\liblzma*.dll" "%PARDIR%" >> "%LOG%" 2>&1
copy /y "%PERLDIST%\c\bin\libcrypto*.dll" "%PARDIR%" >> "%LOG%" 2>&1
copy /y "%PERLDIST%\c\bin\libssl*.dll" "%PARDIR%" >> "%LOG%" 2>&1
REM patch Mozilla::CA
copy /y "%PERLDIST%\perl\vendor\lib\Mozilla\CA.pm" "%PARDIR%\lib\Mozilla\CA.pm" >> "%LOG%" 2>&1
perl -i.bak -p -e "s/__FILE__/\$INC\{\'Mozilla\/CA.pm\'\}/" "%PARDIR%\lib\Mozilla\CA.pm" >> "%LOG%" 2>&1
del "%PARDIR%\lib\Mozilla\CA.pm.bak" >> "%LOG%" 2>&1
call :log ...Finished
REM create archive in build dir
call :log Archiving Perl support files...
set PARZIP=%PERLDIR%\%PARPFX%.zip
del "%PARZIP%" >> "%LOG%" 2>&1
pushd "%PARDIR%"
"%P7ZIP%" a "%PARZIP%" lib licenses *.dll perl.exe >> "%LOG%" 2>&1
popd
call :log ...Finished
call :log FINISH %CMDNAME% %date% %time%
:done
exit /b
:die
echo Exiting - see %LOG%
exit /b 1
:log
echo %*
echo %* >> "%LOG%"
goto :eof
:usage
echo.
echo Create Perl support files for get_iplayer
echo.
echo Usage:
echo   %~n0 GiPVersion SetupBuild
echo   %~n0 /? - this message
echo.
echo Parameters:
echo   GiPVersion - get_iplayer version (X.YY)
echo   SetupBuild - setup build number (Z)
echo.
echo Output (in build\perl):
echo   perl-N.N.N	 - Perl support files
echo   perl-N.N.N.zip - Perl support files archive
echo	 (N.N.N = Perl version)
echo.
echo Input (in build\get_iplayer\get_iplayer-X.YY.Z):
echo   get_iplayer - get_iplayer script
echo   get_iplayer.cgi - web pvr script
echo.
echo Required CPAN modules:
echo   PAR::Packer - archive creation
echo.
