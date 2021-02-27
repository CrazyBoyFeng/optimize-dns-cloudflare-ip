Rem PS1 脚本启动器
Rem PS1 文件不能直接运行，所以需要这个启动器。

@Echo Off
SetLocal EnableDelayedExpansion
Title %~n0
CD /D "%~dp0"

If /I "%1"=="Start" (
    Start /Min Cmd /C "%~dpnx0 NoPause"
    Exit
)

Set Path=%Path%;%SystemRoot%\system32\WindowsPowerShell\v1.0\
PowerShell -ExecutionPolicy Unrestricted -NoProfile -File %~dpn0.ps1
Set ExitCode=%ErrorLevel%
Echo.
If /I "%ExitCode%"=="0" (
    If /I Not "%1"=="NoPause" (
        Pause
    )
) Else (
    Echo Exit Code: %ExitCode%
    Echo.
    Pause
)
Exit %ExitCode%