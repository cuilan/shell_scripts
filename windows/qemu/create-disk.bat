@echo off

@REM enable delayed expansion
setlocal enabledelayedexpansion

set "filename=ubuntu.qcow2"
set "disksize=40G"

if exist "!filename!" (
    echo Disk !filename! exists. Exiting...
	echo.
	pause
    exit
)

@REM Create qcow2 disk size !disksize!
D:\soft\qemu\qemu-img.exe create -f qcow2 !filename! !disksize!

pause