@echo off

@REM enable delayed expansion
setlocal enabledelayedexpansion

set "filename=ubuntu.qcow2"

echo Show !filename! info:
echo --------------------------------
D:\soft\qemu\qemu-img.exe info !filename!

@REM echo print a empty line.
echo.

echo Check !filename! error:
echo --------------------------------
D:\soft\qemu\qemu-img.exe check !filename!

echo.
echo.

pause