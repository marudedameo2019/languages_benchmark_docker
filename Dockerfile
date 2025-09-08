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
    ln -s /root/.local/share/uv/python/cpython-3.12.*-linux-*/bin/python3.12 /usr/bin/python3.12 && \
    ln -s /root/.local/share/uv/python/cpython-3.12.*-linux-*/bin/pip3.12 /usr/bin/pip3.12 && \
    ln -s /usr/bin/ruby /usr/bin/miniruby && \
    npm install -g bun
    
# コンテナ内の作業ディレクトリを設定
WORKDIR /app

# 起動コマンドを設定 (volumeマウント前提)
CMD ["/bin/sh"]
