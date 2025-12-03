#!/bin/sh

# ==============================
#   Minecraft Patcher (Linux/Termux)
# ==============================

# COLOR SET
C0="\033[0m"; C1="\033[1;92m"; C2="\033[1;96m"; C3="\033[1;93m"; C4="\033[1;91m"

echo -e "${C1}=== Minecraft Downloader + Mod Patcher (Linux/Termux) ===${C0}"
sleep 0.5

# -------- DETECT TERMUX -------------
if [ -d /data/data/com.termux/files ]; then
    echo -e "${C2}📱 Termux detected${C0}"
    pkg install python zip unzip curl -y
else
    echo -e "${C2}🖥 Linux detected${C0}"
    if command -v apt >/dev/null; then sudo apt install python3 python3-pip unzip zip curl -y
    elif command -v pacman >/dev/null; then sudo pacman -Sy python-pip zip unzip curl --noconfirm
    elif command -v dnf >/dev/null; then sudo dnf install python3-pip zip unzip curl -y
    fi
fi

# Install Python lib
pip3 install minecraft-launcher-lib >/dev/null 2>&1

# -------- INPUT VERSION -------------
echo -ne "${C3}Введите версию Minecraft: ${C0}"
read VER

# -------- CHECK VERSION > 1.6.4 -------
vernum=$(printf "%s\n1.6.4" "$VER" | sort -V | tail -n1)
if [ "$vernum" = "$VER" ] && [ "$VER" != "1.6.4" ]; then
    echo -e "${C4}⚠ ModLoader работает только до 1.6.4${C0}"
    echo -ne "${C3}Использовать 1.6.4 вместо $VER? (Y/N): ${C0}"
    read A
    case "$A" in y|Y) VER="1.6.4";; esac
fi

echo -e "${C2}⬇ Загрузка Minecraft версии $VER...${C0}"

python3 <<EOF
import minecraft_launcher_lib, os, shutil
ver="$VER"
base = minecraft_launcher_lib.utils.get_minecraft_directory()
minecraft_launcher_lib.install.install_minecraft_version(ver, base)
jar = os.path.join(base,"versions",ver,f"{ver}.jar")
if os.path.exists(jar):
    shutil.copy(jar,f"minecraft_{ver}.jar")
    print("OK")
else:
    print("ERROR")
EOF

# Fail?
if [ ! -f "minecraft_${VER}.jar" ]; then
    echo -e "${C4}❌ Ошибка скачивания!"
    exit 1
fi

# -------- MOD LINKS INPUT -------------
echo -e "${C3}Введите ссылки на моды (пустая строка = конец):${C0}"

MODDIR=".tmp/mcmods"; rm -rf "$MODDIR"; mkdir "$MODDIR"

i=1
while true; do
    echo -ne "URL #$i: "
    read U
    [ -z "$U" ] && break
    curl -L "$U" -o "$MODDIR/mod_$i.zip"
    echo "✔ mod_$i.zip"
    i=$((i+1))
done

# -------- PATCHING -------------
WORK=".tmp"
rm -rf "$WORK"; mkdir -p "$WORK/mc"

echo -e "${C2}📦 Распаковка Minecraft...${C0}"
unzip -qq "minecraft_${VER}.jar" -d "$WORK/mc"

echo -e "${C2}📂 Распаковка модов...${C0}"
mkdir "$WORK/mod"
for z in "$MODDIR"/*.zip; do
    unzip -qq "$z" -d "$WORK/mod"
done

echo -e "${C2}🛠 Применение модов...${C0}"
cp -rf "$WORK/mod/"* "$WORK/mc/" 2>/dev/null
rm -rf "$WORK/mc/META-INF"

echo -e "${C2}📦 Пересборка...${C0}"
cd "$WORK/mc"
zip -qr ../../${VER}.jar .
cd ../../

rm -rf "$WORK"

echo -e "${C1}✔ Готово!
${VER}.jar