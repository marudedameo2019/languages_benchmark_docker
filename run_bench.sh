#!/bin/sh

# ベンチマーク設定
REPO_URL="https://github.com/bddicken/languages"
REPO_DIR="languages"
VIEWER_DIR="languages-simpleplot"
IMAGE_NAME="archbench-env"
CONTAINER_NAME="benchmark-container"
PYTHON_VERSION="3.12"

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
    patch -p1 <<EOF
--- a/run-legacy.sh
+++ b/run-legacy.sh
@@ -23,16 +23,16 @@ function check {
 }
 
 function run {
-  echo ""
+  echo "" >&2
   if [ -f \${2} ]; then
-    check "\${1}" "\${3}" "\${4}"
+    check "\${1}" "\${3}" "\${4}" >&2
     if [ \${?} -eq 0 ] && [ "\${script_args}" != "check" ]; then
       cmd=\$(echo "\${3} \${4}" | awk '{ if (length(\$0) > 80) print substr(\$0, 1, 60) " ..."; else print \$0 }')
-      echo "Benchmarking \$1"
-      hyperfine -i --shell=none --output=pipe --runs 3 --warmup 2 -n "\${cmd}" "\${3} \${4}"
+      echo "Benchmarking \$1" >&2
+      hyperfine -i --shell=none --style none --export-csv - --runs 3 --warmup 2 -n "\$1" "\${3} \${4}"
     fi
   else
-    echo "No executable or script found for \$1. Skipping."
+    echo "No executable or script found for \$1. Skipping." >&2
   fi
 }
 
EOF
    cd ..
else
    echo "リポジトリは既に存在します: $DIR"
    echo "最新の状態に更新します..."
    (cd "$DIR" && git pull)
fi

# ヒアドキュメントでグラフ生成用スクリプトを作成

if [ ! -d "$VIEWER_DIR" ]; then
    mkdir -p "$VIEWER_DIR"
    cd "$VIEWER_DIR"
    cat >plot_current.py <<EOF
import pandas as pd
import plotly.graph_objects as go
from plotly.subplots import make_subplots
from pathlib import Path

csv = list(Path('../languages/').glob('*.csv'))[-1]
print(f'[{csv}]')
df = pd.read_csv(csv, index_col=['benchmark','language'])
print(df)
benchmarks = list(df.index.get_level_values(0).unique())
benchmarks.remove('hello-world')
fig = make_subplots(rows=len(benchmarks), cols=1, subplot_titles=benchmarks)
for idx, benchtype in enumerate(benchmarks):
    df_bench = df.loc[benchtype]
    mean = df_bench['mean-ms']
    df_bench['perf'] = mean.loc['C'] * 100 / mean
    df_bench = df_bench.sort_values(by='mean-ms')
    print(df_bench)
    fig.add_trace(go.Bar(x=df_bench.index, y=df_bench['perf']), row=idx+1, col=1)
fig.update_layout(title_text="current", showlegend=False)
fig.write_html(f'current_chart.html')
EOF
    cat >plot_legacy.py <<EOF
import pandas as pd
import plotly.graph_objects as go
from plotly.subplots import make_subplots

dirs = ['loops', 'fibonacci', 'levenshtein']
fig = make_subplots(rows=len(dirs), cols=1, subplot_titles=dirs)
for idx, dir in enumerate(dirs):
    df = pd.read_csv(f'../languages/{dir}/run_legacy_result.csv', index_col='command')
    mean = df['mean']
    df['perf'] = mean.loc['C'] * 100 / mean
    df = df.sort_values(by='mean')
    print(df)
    fig.add_trace(go.Bar(x=df.index, y=df['perf']), row=idx+1, col=1)
fig.update_layout(title_text="legacy", showlegend=False)
fig.write_html(f'legacy_chart.html')
EOF
    cd ..
fi

echo ""
echo "--- 2. Dockerイメージの存在チェックとビルド ---"

# ヒアドキュメントでDockerfileを作成
cat > Dockerfile <<EOF
# Arch Linuxをベースイメージとして使用
FROM archlinux:latest

# パッケージインストールとユーザー作成
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm base-devel git jdk-openjdk gcc curl clojure uv ruby go nodejs-lts npm rust julia kotlin zig emacs racket \
    hyperfine \
    deno elixir lua php pypy dotnet-sdk nim crystal odin gcc-fortran ghc cabal-install \
    --noprogressbar && \
    pacman -Scc --noconfirm && \
    uv python install 3.12 && \
    ln -s /root/.local/share/uv/python/cpython-${PYTHON_VERSION}.*-linux-*/bin/python${PYTHON_VERSION} /usr/bin/python${PYTHON_VERSION} && \
    ln -s /root/.local/share/uv/python/cpython-${PYTHON_VERSION}.*-linux-*/bin/pip${PYTHON_VERSION} /usr/bin/pip${PYTHON_VERSION} && \
    ln -s /usr/bin/ruby /usr/bin/miniruby && \
    npm install -g bun
    
# コンテナ内の作業ディレクトリを設定
WORKDIR /app

# 起動コマンドを設定 (volumeマウント前提)
CMD ["/bin/sh"]
EOF

docker build -t "$IMAGE_NAME" .
rm Dockerfile

echo ""
echo "--- 3. ベンチマークをDockerコンテナで実行 ---"
echo "マウントするディレクトリ: $(pwd)/$REPO_DIR"

# リポジトリに用意されているスクリプトを直接実行した後、グラフも生成
docker run --rm -i \
    --name "$CONTAINER_NAME" \
    --volume "$(pwd)":/app \
    "$IMAGE_NAME" \
    /bin/bash <<EOF
set -e
legacy=false
current=true
plotonly=false
if [ "$#" = "1" ]; then
    case "$1" in
        legacy)
            legacy=true
            current=false
            ;;
        all)
            legacy=true     
            ;;
        plot)
            current=false
            plotonly=true
            ;;
        *)
            ;;
    esac
fi
cd /app/languages
if [ "\$legacy" = "true" ]; then
    for benchtype in loops fibonacci levenshtein;do
        cd "\$benchtype"
        echo "\$benchtype"
        ../compile-legacy.sh
        ../run-legacy.sh |sed '/^$/d'|sed '2,\${/^command,mean,stddev,median,user,system,min,max$/d}'| tee run_legacy_result.csv
        cd ..
    done
fi
if [ "\$current" = "true" ]; then
    ./compile.sh
    ./run.sh
    cp -p /tmp/languages-benchmark/*.csv .
fi
cd "../$VIEWER_DIR"
if [ ! -d "env" ]; then
    uv venv env
    . env/bin/activate
    uv pip install pandas plotly
else
    . env/bin/activate
fi
if [ "\$current" = "true" -o "\$plotonly" = "true" ]; then
    python plot_current.py
fi
if [ "\$legacy" = "true" -o "\$plotonly" = "true" ]; then
    python plot_legacy.py
fi
deactivate
cd ..
EOF

echo ""
echo "--- ベンチマーク実行完了 ---"

