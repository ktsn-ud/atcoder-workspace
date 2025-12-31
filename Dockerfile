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

# Precompile bits/stdc++.h for faster compilation
RUN STDC_HEADER_PATH=$(find /usr/include -name stdc++.h 2>/dev/null | head -1) && \
  if [ -n "$STDC_HEADER_PATH" ]; then \
    g++ -std=gnu++23 -O1 -x c++-header "$STDC_HEADER_PATH" -o "${STDC_HEADER_PATH}.gch" && \
    echo "Precompiled: $STDC_HEADER_PATH"; \
  fi

# bash config
COPY .bashrc /root/.bashrc

ENV PATH="/opt/nvim-linux-arm64/bin:/workspace/scripts:${PATH}"

WORKDIR /workspace

