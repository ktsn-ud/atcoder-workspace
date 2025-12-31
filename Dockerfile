FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV CC_PORT=10043

RUN apt-get update && apt-get install -y --no-install-recommends \
  nodejs npm \
  ca-certificates curl git \
  python3 python3-pip \
  pypy3 \
  g++ make clangd \
  time \
  unzip \
  ripgrep \
  fd-find \
  && rm -rf /var/lib/apt/lists/*

# install ac-library
RUN git clone --depth 1 https://github.com/atcoder/ac-library.git /opt/ac-library \
  && mkdir -p /usr/local/include \
  && cp -r /opt/ac-library/atcoder /usr/local/include/ \
  && rm -rf /opt/ac-library

# install neovim
RUN curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-arm64.tar.gz \
  && rm -rf /opt/nvim-linux-arm64 \
  && tar -C /opt -xzf nvim-linux-arm64.tar.gz

# bash config
COPY .bashrc /root/.bashrc

ENV PATH="/opt/nvim-linux-arm64/bin:/workspace/scripts:${PATH}"

WORKDIR /workspace

