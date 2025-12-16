FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV CC_PORT=10043

RUN apt-get update && apt-get install -y --no-install-recommends \
  ca-certificates curl git \
  python3 python3-pip \
  pypy3 \
  g++ make \
  time \
  && rm -rf /var/lib/apt/lists/*

# install ac-library
RUN git clone --depth 1 https://github.com/atcoder/ac-library.git /opt/ac-library \
  && mkdir -p /usr/local/include \
  && cp -r /opt/ac-library/atcoder /usr/local/include/ \
  && rm -rf /opt/ac-library

WORKDIR /workspace

