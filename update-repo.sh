#!/data/data/com.termux/files/usr/bin/bash

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🚀 开始更新仓库..."

cd "$REPO_DIR"

mkdir -p dists/stable/main/binary-aarch64
mkdir -p dists/stable/main/binary-all
mkdir -p pool/main

if ls *.deb >/dev/null 2>&1; then
    echo "移动 .deb 文件到 pool/main..."
    mv *.deb pool/main/
fi

rm -f Packages Packages.gz Release InRelease

echo "生成 aarch64 架构 Packages..."
cd "$REPO_DIR"
# 使用正确的路径生成
dpkg-scanpackages pool/main /dev/null | sed 's|^Filename: ./|Filename: ../../../pool/main/|' > dists/stable/main/binary-aarch64/Packages

echo "生成 all 架构 Packages..."
cd "$REPO_DIR"  
dpkg-scanpackages pool/main /dev/null | sed 's|^Filename: ./|Filename: ../../../pool/main/|' > dists/stable/main/binary-all/Packages

echo "压缩 Packages 文件..."
gzip -k -f dists/stable/main/binary-aarch64/Packages
gzip -k -f dists/stable/main/binary-all/Packages

echo "生成 Release 文件..."
cd dists/stable
cat > Release << EOF
Origin: csf0304
Label: csf0304 Repo
Suite: csf0304
Codename: stable
Architectures: aarch64 all
Components: main
Description: csf0304's Termux package repository
Date: $(date -Ru)
EOF
apt-ftparchive release . >> Release
cd "$REPO_DIR"

echo "签名 Release 文件..."
cd dists/stable
gpg --clearsign -o InRelease Release
cd "$REPO_DIR"

echo "导出公钥..."
gpg --export --armor csf0304 > csf0304.asc

echo "✅ 本地更新完成"

if [ "$1" = "--deploy" ] || [ "$1" = "-d" ]; then
    echo "开始部署到 GitHub..."
    
    if [ ! -d ".git" ]; then
        echo "⚠️  不是 git 仓库，跳过部署"
        exit 0
    fi

    git add -A
    git commit -m "chore: Update packages $(date +%Y%m%d-%H%M%S)"
    git push -f origin main
    echo "✅ 部署到 GitHub 完成"
fi

echo "📦 当前包列表:"
dpkg-scanpackages pool/main /dev/null | grep "^Package:" | awk '{print "  - " $2}'
