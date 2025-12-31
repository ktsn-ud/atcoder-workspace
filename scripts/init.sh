#!/bin/bash

set -euo pipefail

cleanup_and_exit() {
  echo
  echo "Interrupted" >&2
  kill 0 2>/dev/null || true
  exit 130
}

trap cleanup_and_exit INT TERM

# 言語インストール確認
echo "[acc-init] checking language status..."

if type "python3" >/dev/null 2>&1; then
  echo "[acc-init] Python3 is already installed ...OK"
else
  echo "[acc-init] Python3 not installed." >&2
  exit 1
fi

if type "pip3" >/dev/null 2>&1; then
  echo "[acc-init] pip3 is already installed ...OK"
else
  echo "[acc-init] pip3 not installed." >&2
fi

if type "g++" >/dev/null 2>&1; then
  echo "[acc-init] g++ is already installed ...OK"
else
  echo "[acc-init] g++ not installed." >&2
  exit 1
fi

# プロジェクトのルートディレクトリを特定
script_real="$(python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "${BASH_SOURCE[0]}")"
script_abspath="$(cd "$(dirname "$script_real")" && pwd)"
repo_root="$(cd "$script_abspath/.." && pwd)"

# ac-library インストール
if [[ -d $repo_root/.include/atcoder ]]; then
  echo "[acc-init] ac-library found at $repo_root/.include/atcoder."
  echo "[acc-init] skip installing."
else
  echo "[acc-init] installing ac-library..."
  git clone --depth 1 https://github.com/atcoder/ac-library.git /tmp/ac-library
  mkdir -p $repo_root/.include
  cp -r /tmp/ac-library/atcoder $repo_root/.include/
  rm -rf /tmp/ac-library
  echo "[acc-init] ac-library has been successfully installed in $repo_root/.include."
fi

# venv セットアップ
if [[ -d "$repo_root/.venv" ]]; then
  echo "[acc-init] .venv directory found."
else
  echo "[acc-init] $repo_root/.venv not found. creating virtual env..."
  python3 -m venv .venv
  echo "[acc-init] .venv has been created."
fi

# アクティベート
source $repo_root/.venv/bin/activate
echo "[acc-init] .venv has been activated."

# 依存のインストール
if [[ -e "$repo_root/requirements.txt" ]]; then
  echo "[acc-init] requirements.txt found. installing requirements..."
  pip3 install -r ${repo_root}/requirements.txt
fi
