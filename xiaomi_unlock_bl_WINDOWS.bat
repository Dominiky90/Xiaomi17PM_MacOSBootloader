@ECHO OFF
cd /d %~dp0bin
TITLE 小米骁龙8E5一键解锁BL

ECHO.
ECHO.[适用设备]
ECHO.- 理论上: 所有小米红米骁龙8EliteGen5处理器设备
ECHO.- 小米17
ECHO.- 小米17Pro
ECHO.- 小米17ProMax
ECHO.- 小米17Ultra
ECHO.- 红米K90ProMax
ECHO.
ECHO.[注意事项]
ECHO.- 解锁会自动清除设备内所有用户数据, 请务必提前备份到电脑或云端
ECHO.- 解锁前请关闭查找手机, 退出小米帐号, 删除指纹数据, 删除锁屏密码
ECHO.- 其他设备不保证可用, 使用变砖后果自负
ECHO.- 仅供个人学习研究, 请勿用于非法用途, 否则后果自负
ECHO.
ECHO.了解以上事项, 请按任意键继续... & pause>nul
ECHO.
ECHO.请将手机连接电脑, 并开启USB调试...
:A
adb.exe devices | find /v "List of devices attached" | find "device" 1>nul 2>nul || goto A
ECHO.设备已连接
ECHO.
ECHO.设备型号: & adb.exe shell getprop ro.product.marketname || goto FAILED
ECHO.系统信息: & adb.exe shell getprop ro.build.fingerprint || goto FAILED
ECHO.安全补丁版本: & adb.exe shell getprop ro.vendor.build.security_patch || goto FAILED
ECHO.
ECHO.重启到Fastboot... & adb.exe reboot bootloader || goto FAILED
ECHO.等待设备连接...
:B
fastboot.exe devices 2>&1 | find "fastboot" || goto B
ECHO.设备已连接
ECHO.检查解锁状态...
fastboot.exe getvar unlocked 2>&1 | find "unlockd: yes" 1>nul 2>nul && ECHO.设备已解锁, 无需重复解锁. 按任意键退出... && pause>nul && EXIT
ECHO.临时宽容SELinux...
fastboot.exe oem set-gpu-preemption-value 0 androidboot.selinux=permissive 1>log1.txt 2>&1 || fastboot.exe reboot && goto FAILED
fastboot.exe continue 1>log2.txt 2>&1 || goto FAILED
ECHO.等待设备连接...
:C
adb.exe devices | find /v "List of devices attached" | find "device" 1>nul 2>nul || goto C
ECHO.设备已连接
ECHO.检查SELinux状态... & adb.exe shell getenforce>log3.txt || goto FAILED
find "Permissive" "log3.txt" 1>nul 2>nul || goto FAILED
ECHO.写入解锁程序...
adb.exe push linuxloader_unlock.efi /data/local/tmp/linuxloader_unlock.efi 1>nul || goto FAILED
adb.exe shell service call miui.mqsas.IMQSNative 21 i32 1 s16 "dd" i32 1 s16 'if=/data/local/tmp/linuxloader_unlock.efi of=/dev/block/by-name/efisp' s16 '/data/mqsas/log.txt' i32 60 1>log4.txt 2>&1 || goto FAILED
ECHO.重启到fastboot... & adb.exe reboot bootloader || goto FAILED
ECHO.等待设备连接...
:D
fastboot.exe devices 2>&1 | find "fastboot" || goto D
ECHO.设备已连接
ECHO.检查解锁状态...
fastboot.exe getvar unlocked 1>log5.txt 2>&1 || goto FAILED
find "unlocked: yes" "log5.txt" 1>nul 2>nul || goto FAILED
ECHO.
ECHO.恭喜! 解锁成功
ECHO.
ECHO.清空efisp分区... & fastboot.exe flash efisp efisp_blank.img || ECHO.失败
ECHO.重启并自动恢复出厂...
fastboot.exe flash misc misc_wipedata_mi.img || ECHO.失败
fastboot.exe reboot || ECHO.失败
ECHO.
ECHO.全部完成. 按任意键退出...
ECHO.
pause>nul
EXIT


:FAILED
ECHO. & ECHO.失败. 按任意键退出... & pause>nul & EXIT

