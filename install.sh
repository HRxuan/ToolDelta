#!/bin/bash
# 设置安装目录
install_dir="$PWD/tooldelta"
# 设置应用程序名称
app_name="ToolDelta"
# 设置快捷指令
shortcut_command="td"


function EXIT_FAILURE(){
    exit -1
}

function download_exec_for_termux(){
echo "开始更新系统环境，遇到停顿请回车"
sleep 5
#更换termux源
sed -i 's@^\(deb.*stable main\)$@#\1\ndeb https://mirrors.tuna.tsinghua.edu.cn/termux/termux-packages-24 stable main@' $PREFIX/etc/apt/sources.list && apt update

# 使用apt安装Python
echo "正在使用 apt 安装 Python及相关环境..."
apt install python python-numpy python-pillow git libexpat -y

# 安装 PIL 的前置库
echo "正在安装图片处理依赖库(用于地图画导入)..."
apt install libjpeg-turbo -y
apt install zlib -y

#更换pip源


# 安装tooldelta库
echo "安装tooldelta..."
gitclone="https://github.dqyt.online/https://github.com/ToolDelta-Basic/ToolDelta"
until timeout 5m git clone "$gitclone";do
  echo "下载失败，5秒后切换镜像源"
  sleep 5
  ((N++))
  case "$N" in
    1)gitclone="https://github.moeyy.xyz/https://github.com/ToolDelta-Basic/ToolDelta";;
    2)echo "你的网络似乎有什么问题呢？请稍后重新尝试吧";EXIT_FAILURE;;
    *)gitclone="https://github.com/ToolDelta-Basic/ToolDelta";N=0
  esac
done
cd ToolDelta
echo "开始安装环境"
until timeout 5m pip install psutil ujson colorama shellescape pyspeedtest aiohttp python-socketio flask websocket-client fcwslib pyyaml brotli websockets tqdm anyio requests sqlite-easy-ctrl;do
  echo "下载失败，5秒后切换镜像源"
  sleep 5
  ((N++))
  case "$N" in
    1)pip config set global.index-url http://mirrors.aliyun.com/pypi/simple;;
    2)echo "你的网络似乎有什么问题呢？请稍后重新尝试吧";rm -r ../ToolDelta ;EXIT_FAILURE;;
    *)pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple;N=0
  esac
done
# 生成main.py文件
echo "生成快捷入口..."
 cat > "/data/data/com.termux/files/usr/bin/$shortcut_command" << EOF
python /data/data/com.termux/files/home/ToolDelta/main.py
EOF
chmod +x "/data/data/com.termux/files/usr/bin/$shortcut_command"
echo "安装完成啦，您现在可以在命令行中输入 '$shortcut_command' 来启动 $app_name。"

}

function download_exec(){
# 权限
mkdir -p "$install_dir"
chown -R +x "$install_dir"

# 切换到安装目录
pushd "$install_dir" || exit
# 获取ToolDelta的最新版本
LatestTag=$(wget -qO- -t1 -T2 "https://tdload.tblstudio.cn/https://api.github.com/repos/ToolDelta/ToolDelta/releases/latest" | jq -r '.tag_name')
# 设置 GitHub release URL
github_release_url="https://tdload.tblstudio.cn/https://github.com/ToolDelta/ToolDelta/releases/download/${LatestTag}/ToolDelta-linux"
# 下载
if curl -o "$app_name" -L "$github_release_url"; then
    echo "下载完成。"
else
    echo "下载失败。请检查网络连接或稍后再试。"
    exit 1
fi

# 权限
chmod 777 "$app_name"
case ${PLANTFORM} in
    "Linux_x86_64")
    executable="/usr/local/bin/$shortcut_command"
    ;;
    "Andorid_armv8")
    executable="/data/data/com.termux/files/usr/bin/$shortcut_command"
    ;;
    *)
    echo "不支持的平台${PLANTFORM}"
    EXIT_FAILURE
    ;;
esac

if ln -s "$install_dir/start.sh" $executable; then
    echo "快捷指令 '$shortcut_command' 创建成功。"
else
    echo "创建快捷指令 '$shortcut_command' 失败。请检查权限或手动创建快捷指令。"
fi
# 生成start.sh脚本
echo "pushd $install_dir && ./$app_name && popd " >  "$install_dir/start.sh"
chmod 777 "$install_dir/start.sh"
echo "安装完成啦，您现在可以在命令行中输入 '$shortcut_command' 来启动 $app_name。"
}

if [[ $(uname -o) == "GNU/Linux" ]] || [[ $(uname -o) == "GNU/Linux" ]]; then
    PLANTFORM="Linux_x86_64"
    if [[ $(uname -m) != "x86_64" ]]; then
        echo "不支持非64位的Linux系统"
        EXIT_FAILURE
    fi
    download_exec
elif [[ $(uname -o) == "Android" ]]; then
    PLANTFORM="Andorid_armv8"
    if [[ $(uname -m) == "armv7" ]]; then
        echo "不支持armv7的Andorid系统"
        EXIT_FAILURE
    fi
    echo "检测文件权限中..."
    if [ ! -x "/sdcard/Download" ]; then
        echo "请给予 termux 文件权限 ~"
        sleep 2
        termux-setup-storage
        EXIT_FAILURE
    fi
    if [ -x "/sdcard/Download" ]; then
        echo -e ""
        # working_dir="/sdcard/Download"
        # executable="/sdcard/Download/fastbuilder"
    else
        red_line "拜托你很逊欸，没权限"
        EXIT_FAILURE
    fi
    # dialog --menu "请选择安装方法" 15 40 4 1 "脚本安装(推荐)" 2 "覆盖安装(当方法1无法使用时使用)" 2> 1
      # case "$(cat 1)" in
        # 1)
        # download_exec_for_termux
        # ;;
        # 2)
        # Download_termux
        # ;;
        # *)
        # EXIT_FAILURE
    # esac
    download_exec_for_termux

else
    echo "不支持该系统，你的系统是"
    uname -a
fi


popd
