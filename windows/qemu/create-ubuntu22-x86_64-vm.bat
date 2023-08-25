@echo off

@REM enable delayed expansion
setlocal enabledelayedexpansion

set "filename=ubuntu.qcow2"

if not exist "!filename!" (
    echo Disk !filename! dose not exists. Exiting...
	echo.
	pause
    exit
)

echo Disk !filename! exists.
echo Create ubuntu x86_64 vm 2CPU/4GB.

D:\soft\qemu\qemu-system-x86_64.exe ^
	-enable-kvm ^
	-m 4G ^
	-smp 2 ^
	-cpu host-passthrough ^
	-drive format=raw,file=ubuntu.qcow2 ^
	-cdrom D:\qemuvm\ubuntu-22.04-server-cloudimg-amd64.img ^
	-boot d

pause