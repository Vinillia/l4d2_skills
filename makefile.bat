@echo off
setlocal enableDelayedExpansion

set compiler="D:/!%Sentience%!/scripting/spcomp.exe"
set includes="!%Sentience%!/scripting/include/"
set path=%cd%

if not exist ./plugins/l4d2_skills_modules\ (
	mkdir "%path%/plugins/l4d2_skills_modules"
)

(for /f delims^= %%i in ('dir /b %path%\scripting\*.sp') do (
    %compiler% -D%path%\scripting -i%includes% -i%path%\scripting\include\ %%i
))

(for /f delims^= %%i in ('dir /b %path%\scripting\l4d2_skills_modules\*.sp') do (
    %compiler% -D%path%\scripting\l4d2_skills_modules\ -i%includes% -i%path%\scripting\include\ %%i
))

(for /f delims^= %%i in ('dir /b %path%\scripting\*.smx') do (
    move %path%\scripting\%%i ./plugins/
))

(for /f delims^= %%i in ('dir /b %path%\scripting\l4d2_skills_modules\*.smx') do (
    move %path%\scripting\l4d2_skills_modules\%%i ./plugins/l4d2_skills_modules/
))