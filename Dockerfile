FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV CC_PORT=10043

RUN apt-get update && apt-get install -y --no-install-recommends \
  ca-certificates curl git \
  python3 python3-pip \
  g++ make \
  time \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

