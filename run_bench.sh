#!/bin/sh

# ベンチマーク設定
REPO_URL="https://github.com/bddicken/languages"
REPO_DIR="languages"
IMAGE_NAME="archbench-env"
CONTAINER_NAME="benchmark-container"

# エラーが発生した場合、即座に終了
set -e

echo "--- 1. GitHubリポジトリをクローン ---"
URL="$REPO_URL"
DIR=$(echo "$URL"|sed 's/^.*\///')
echo "$DIR"
if [ ! -d "$DIR" ]; then
    echo "リポジトリをクローンします: $URL"
    git clone "$URL"
    cd "$DIR"
    patch -p1 <../run_legacy.patch
    cd ..
else
    echo "リポジトリは既に存在します: $DIR"
    echo "最新の状態に更新します..."
    (cd "$DIR" && git pull)
fi

echo ""
echo "--- 2. Dockerイメージのビルド ---"

docker build -t "$IMAGE_NAME" .

echo ""
echo "--- 3. ベンチマークをDockerコンテナで実行 ---"

# リポジトリに用意されているスクリプトを直接実行した後、グラフも生成
docker run --rm -i \
    --name "$CONTAINER_NAME" \
    --volume "$(pwd)":/app \
    "$IMAGE_NAME" \
    /bin/bash <run_on_docker.sh

echo ""
echo "--- ベンチマーク実行完了 ---"

