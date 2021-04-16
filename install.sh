#! /usr/bin/env bash
#set -x
node=$(command -v node)
client=$(command -v netease-cloud-music)
proxy=""
httpsPort="5620"
httpPort="5621"
installDir="$HOME/.config/netease"
proxyDir="$installDir/proxy"

# COLORS
CDEF=" \033[0m"                                     # default color
CCIN=" \033[0;36m"                                  # info color
CGSC=" \033[0;32m"                                  # success color
CRER=" \033[0;31m"                                  # error color
CWAR=" \033[0;33m"                                  # warning color
b_CDEF=" \033[1;37m"                                # bold default color
b_CCIN=" \033[1;36m"                                # bold info color
b_CGSC=" \033[1;32m"                                # bold success color
b_CRER=" \033[1;31m"                                # bold error color
b_CWAR=" \033[1;33m"                                # bold warning color


read -r -d '' NGINXCONF <<'EOF'
server {
    listen 80;
    server_name music.163.com interface.music.163.com;
    location / {
            proxy_pass http://127.0.0.1:{httpPort};
            proxy_set_header HOST 'music.163.com';
    }
}
server {
    listen 443 ssl;
    server_name music.163.com interface.music.163.com;
    location / {
            proxy_pass https://127.0.0.1:{httpsPort};
            proxy_set_header HOST 'music.163.com';
    }
}
EOF

read -r -d '' NETEASESERVICE <<'EOF'
[Unit]
Description=netease proxy service
After=network.target
[Service]
User={u}
Group={g}
WorkingDirectory={w}
ExecStart={node} {h}
Restart=always
[Install]
WantedBy=multi-user.target
EOF

usage() {
  printf "%s\n" "Usage: $0 [OPTIONS...]"
  printf "\n%s\n" "OPTIONS:"
  printf "  %-25s%s\n" "-s, --https port" "Specify netease proxy https listen port"
  printf "  %-25s%s\n" "-h, --http port" "Specify netease proxy http listen port"
  printf "  %-25s%s\n" "-p, --proxy " "Specify http proxy for download github file"
  printf "  %-25s%s\n" "--help" "Show this help"
}



# Echo like ... with flag type and display message colors
prompt () {
  case ${1} in
    "-s"|"--success")
      echo -e "${b_CGSC}${@/-s/}${CDEF}";;    # print success message
    "-e"|"--error")
      echo -e "${b_CRER}${@/-e/}${CDEF}";;    # print error message
    "-w"|"--warning")
      echo -e "${b_CWAR}${@/-w/}${CDEF}";;    # print warning message
    "-i"|"--info")
      echo -e "${b_CCIN}${@/-i/}${CDEF}";;    # print info message
    *)
    echo -e "$@"
    ;;
  esac
}


function download {
  prompt -i "Info: Download exetuable file from github"
  wget https://github.com/nondanee/UnblockNeteaseMusic/archive/refs/heads/master.zip -O $installDir/netease.zip
  rm -rf $proxyDir
  unzip -o -qq $installDir/netease.zip -d $installDir/
  mv -f -u $installDir/UnblockNeteaseMusic-master  $proxyDir
  if [[ $node == "" ]];then
      nodedir="node-$(wget -qO- https://nodejs.org/dist/latest/ | sed -nE 's|.*>node-(.*)\.pkg</a>.*|\1|p')-linux-x64"
      curl "https://nodejs.org/dist/latest/$nodedir.tar.gz" > $installDir/node.tar.gz
      tar xzf $installDir/node.tar.gz -C $installDir/
      node="$HOME/.config/netease/$nodedir/bin/node"
  fi
  prompt -s "Success: Download require exetuable file."
}
function setupHosts {
    echo "#music.163.com\n127.0.0.1 music.163.com\n127.0.0.1 interface.music.163.com" | sudo tee -a /etc/hosts > /dev/null
    prompt -s "Success: Add music.163.com domain to hosts."
}
function setupService {
    echo "$NETEASESERVICE" \
    | sed "s|{node}|$node|g"  \
    | sed  "s|{h}|$proxyDir/app.js -p $httpPort:$httpsPort -f 59.111.181.60|g" \
    | sed  "s|{u}|$USER|g" \
    | sed  "s|{g}|$USER|g" \
    | sed  "s|{w}|$proxyDir/|g" \
    | sudo tee /lib/systemd/system/netease.service > /dev/null
    sudo systemctl daemon-reload
    sudo systemctl stop netease.service
    sudo systemctl start netease.service
    sudo systemctl enable netease.service
    #sudo systemctl status netease.service
    prompt -s "Success: Setup netease music proxy service."
}

function setupNginx {
    echo "$NGINXCONF" \
    | sed "s|{httpPort}|$httpPort|g" \
    | sed  "s|{httpsPort}|$httpsPort|g" \
    | sudo tee /etc/nginx/conf.d/netease.conf > /dev/null
    #sudo nginx -t
    sudo service nginx restart
    prompt -s "Success: Setup nginx service."
}



function setupExec {
  ingore="--ignore-certificate-errors"
  desktop="/usr/share/applications/netease-cloud-music.desktop"
  if [[ -f $desktop ]];then
    execCommand=$(grep Exec=netease-cloud-music $desktop)
    if [[ ! $execCommand =~ .*"$ingore".*  ]];then
      execCommand="$execCommand $ingore"
      sed "s/Exec=netease-cloud-music.*/$execCommand/g" $desktop | sudo tee $desktop > /dev/null
      xdg-desktop-menu forceupdate
    fi
    prompt -s "Success: Add $ingore to desktop exec command."
  else
    prompt -e "ERROR: $desktop: no such file or directory."
  fi
  
}

function setup {
    mkdir -p $installDir
    prompt -i "Info: Install dependencies"
    sudo apt-get install nginx wget curl unzip -y > /dev/null
    if [[ $proxy != "" ]];then
        export http_proxy=$proxy
    fi
    download
    setupService
    setupNginx
    setupHosts
    setupExec
}

if [[ client == "" ]];then
  prompt -i "Info: Please install netease music https://music.163.com/#/download"
  exit 0
fi

while [[ $# -gt 0 ]]; do
    case "${1}" in
        --help)
            usage
            exit 0
            ;;
        -s|--https)
            httpsPort=$2
            shift 2
            ;;
        -h|--http)
            httpPort=$2
            shift 2
            ;;
        -p|--proxy)
            proxy=$2
            shift 2
            ;;
        *)
        prompt -e "ERROR: Unrecognized installation option '$1'."
        prompt -i "Try '$0 --help' for more information."
        exit 1
        ;;
    esac
done

setup