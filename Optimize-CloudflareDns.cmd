Rem PS1 脚本启动器
Rem PS1 文件不能直接运行，所以需要这个启动器。
Rem 本来我是想直接写成 Batch 批处理的，结果发现 CMD 不支持 2 KB 以上的变量，也难以处理 JSON 和 CSV 数据，于是只好写成 PowerShell 脚本。

@Echo Off
Title %~n0
CD /D "%~dp0"

If "%1"=="start" (
    Start /Min Cmd /C"%~dpnx0"
    Exit
)

Set Path=%Path%;%SystemRoot%\system32\WindowsPowerShell\v1.0\
PowerShell -ExecutionPolicy Unrestricted -NoProfile -File %~dpn0.ps1
Set ExitCode=%ErrorLevel%
Echo.
If "%ExitCode%"=="0" (
    If Not "%1"=="start" (
        Pause
    )
) Else (
    Echo Exit Code: %ExitCode%
    Echo.
    Pause
)
Exit %ExitCode%