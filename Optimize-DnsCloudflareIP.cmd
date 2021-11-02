@Echo Off
Rem PS1 脚本启动器
Rem PS1 文件不能直接运行所以需要启动器
Rem 使用参数 Minimized 最小化模式启动
Rem 使用参数 Hidden 隐藏模式启动
Rem 其它参数会传递给 PS1 脚本
SetLocal EnableDelayedExpansion
Title %~n0
CD /D "%~dp0"
Set Path=!Path!;!SystemRoot!\System32\WindowsPowerShell\v1.0\
If /I "%1"=="Minimized" (
    Shift /1
    PowerShell -ExecutionPolicy Unrestricted -NoProfile -WindowStyle Minimized -File "%~dpn0.ps1" %*
    Set ExitCode=!ErrorLevel!
    If Not "!ExitCode!"=="0" (
        Echo.
        Echo Exit Code: !ExitCode! 1>&2
        Echo.
        Pause
    )
) Else If /I "%1"=="Hidden" (
    Shift /1
    PowerShell -ExecutionPolicy Unrestricted -NoProfile -WindowStyle Hidden -File "%~dpn0.ps1" %*
    Set ExitCode=!ErrorLevel!
    If Not "!ExitCode!"=="0" (
        Echo.
        Echo Exit Code: !ExitCode! 1>&2
    )
) Else (
    PowerShell -ExecutionPolicy Unrestricted -NoProfile -File "%~dpn0.ps1" %*
    Set ExitCode=!ErrorLevel!
    Echo.
    Pause
)
Exit !ExitCode!