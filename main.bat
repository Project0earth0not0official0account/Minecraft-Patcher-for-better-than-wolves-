@echo off
chcp 65001 >nul

title Minecraft Universal Patcher (Windows)
echo.
echo ==========================================
echo   Minecraft Downloader + Mod Patcher
echo ==========================================
echo.

:: ---- CHECK PYTHON ----
python --version >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Python не найден!
    echo Установи Python: https://python.org
    pause
    exit /b
)

:: ---- CHECK WINGET ----
winget --version >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Winget не найден!
    echo Обнови Windows или поставь App Installer.
    pause
    exit /b
)

:: ---- INSTALL ZIP ----
where zip >nul 2>nul
if %errorlevel% neq 0 (
    echo Устанавливаю zip/unzip...
    winget install GnuWin32.Zip -h
)

pip install minecraft-launcher-lib >nul

set /p VER=Введите версию Minecraft: 

:: --- CHECK > 1.6.4 ---
for /f %%A in ('powershell -NoP -C "[version]'%VER%' -gt [version]'1.6.4'"') do set BIG=%%A
if "%BIG%"=="True" (
    echo ModLoader работает только до 1.6.4
    set /p A=Использовать 1.6.4? (Y/N):
    if /I "%A%"=="Y" set VER=1.6.4
)

echo Загружаю Minecraft %VER%...

python - <<EOF
import minecraft_launcher_lib, os, shutil
ver="%VER%"
base = minecraft_launcher_lib.utils.get_minecraft_directory()
minecraft_launcher_lib.install.install_minecraft_version(ver, base)
jar = os.path.join(base,"versions",ver,f"{ver}.jar")
if os.path.exists(jar):
    shutil.copy(jar,f"minecraft_{ver}.jar")
    print("OK")
else:
    print("ERROR")
EOF

if not exist minecraft_%VER%.jar (
    echo Ошибка скачивания!
    pause
    exit /b
)

mkdir mods_tmp >nul
set COUNT=1

echo Введите ссылки на моды (пустая строка = конец):

:LOOP
set /p URL=URL #%COUNT%:
if "%URL%"=="" goto CONT
curl -L "%URL%" -o "mods_tmp\mod_%COUNT%.zip"
set /a COUNT+=1
goto LOOP

:CONT

mkdir patch
mkdir patch\mc

echo Распаковка Minecraft...
powershell -NoP -C "Expand-Archive -Force 'minecraft_%VER%.jar' 'patch\mc'"

echo Распаковка модов...
mkdir patch\mod

for %%f in (mods_tmp\*.zip) do powershell -NoP -C "Expand-Archive -Force '%%f' 'patch\mod'"

echo Применение модов...
xcopy patch\mod\* patch\mc\ /E /I /Y >nul
rmdir /S /Q patch\mc\META-INF >nul 2>nul

echo Пересборка...
powershell -NoP -C "Compress-Archive -Path 'patch\mc\*' -DestinationPath '%VER%.jar' -Force"

rmdir /S /Q patch >nul

echo Готово!
echo %VER%.jar
pause