#!/data/data/com.termux/files/usr/bin/bash

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🚀 开始更新仓库..."

cd "$REPO_DIR"

# 创建标准目录结构
mkdir -p dists/stable/main/binary-all
mkdir -p pool/main

# 移动 .deb 文件到 pool
if ls *.deb >/dev/null 2>&1; then
    echo "移动 .deb 文件到 pool/main..."
    mv *.deb pool/main/
fi

echo "生成 Packages 文件..."
cd dists/stable/main/binary-all
dpkg-scanpackages ../../../../pool/main /dev/null > Packages
cd "$REPO_DIR"

echo "压缩 Packages 文件..."
gzip -k -f dists/stable/main/binary-all/Packages

echo "生成 Release 文件..."
cd dists/stable
apt-ftparchive release . > Release
cd "$REPO_DIR"

echo "签名 Release 文件..."
cd dists/stable
gpg --clearsign -o InRelease Release
cd "$REPO_DIR"

echo "✅ 本地更新完成"

if [ "$1" = "--deploy" ] || [ "$1" = "-d" ]; then
    echo "开始部署到 GitHub..."
    
    if [ ! -d ".git" ]; then
        echo "⚠️  不是 git 仓库，跳过部署"
        exit 0
    fi

    # 强制推送，不处理冲突
    echo "强制推送到 GitHub..."
    git add -A
    git commit -m "chore: Update packages $(date +%Y%m%d-%H%M%S)"
    git push -f origin main
    echo "✅ 部署到 GitHub 完成"
fi

echo "📦 当前包列表:"
dpkg-scanpackages pool/main /dev/null | grep "^Package:" | awk '{print "  - " $2}'
