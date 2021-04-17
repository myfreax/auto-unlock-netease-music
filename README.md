# 自动解锁网易云音乐脚本
网易音乐代理服务将会在开机时自动启动，不必每次都需要手动启动

基于以下技术构建
- Nginx
- Systemd
- Node
- /etc/hosts



## 安装 Setup
```bash
bash  -c "$(curl -fsSL https://raw.githubusercontent.com/huangyanxiong01/auto-unlock-netease-music/main/install.sh) -s 5620 -h 5621"
```

## 测试通过
- [x] Ubuntu 20.04
- [ ] Ubuntu 18.04
- [ ] Centos
- [ ] ArchLinux
- [ ] LinuxMint
- [ ] Debian Linux
> 欢迎测试提交PR

## 升级到最新代理服务

只需要重新执行安装步骤即可

## 示例 Example
```bash
./install.sh -s 5620 -h 5621 -p http://127.0.0.1:8889
```

## 文档 Docs

```bash
./install.sh --help
```
```bash
Usage: ./install.sh [OPTIONS...]

OPTIONS:
  -s, --https port         Specify netease proxy https listen port
  -h, --http port          Specify netease proxy http listen port
  -p, --proxy              Specify http proxy for download github file
  --help                   Show this help
```

## Windows?
欢迎你的PR

## 致谢

[nondanee/UnblockNeteaseMusic](https://github.com/nondanee/UnblockNeteaseMusic)
