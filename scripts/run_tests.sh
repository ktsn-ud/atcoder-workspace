#!/usr/bin/env bash
set -euo pipefail

cleanup_and_exit() {
  echo
  echo "Interrupted" >&2
  kill 0 2>/dev/null || true
  exit 130
}

trap cleanup_and_exit INT TERM

# コンテナ内のリポジトリルート
repo_root="/workspace"

# envファイルを読み込む
ACC_ENV_FILE="$repo_root/.config/env"
if [[ -f "$ACC_ENV_FILE" ]]; then
  source "$ACC_ENV_FILE"
fi

: "${CXX:=g++}"
: "${CXXSTD:=gnu++23}"

style_tag() {
  local text="$1"
  local color="${2:-default}" # red|green|default
  local weight="${3:-normal}" # bold|normal

  local code=""
  case "$color" in
  red) code="31" ;;
  green) code="32" ;;
  default) code="" ;;
  *) code="" ;;
  esac

  local sgr=""
  if [[ "$weight" == "bold" ]]; then
    sgr="1"
  fi
  if [[ -n "$code" ]]; then
    [[ -n "$sgr" ]] && sgr="${sgr};${code}" || sgr="${code}"
  fi

  printf '\033[%sm%s\033[0m' "$sgr" "$text"
}

lang="${1:-cpp}"
work="${2:-.}"
cd "$work"

if [ ! -d tests ]; then
  echo "tests/ not found in $(pwd)" >&2
  exit 1
fi

# コードの実行コマンドを保存しておく
run_cmd=()
cleanup=()

if [ "$lang" = "cpy" ]; then
  # Prefer venv Python if available
  if [ -x "/workspace/.venv/bin/python" ]; then
    run_cmd=(/workspace/.venv/bin/python main.py)
  else
    run_cmd=(python3 main.py)
  fi
elif [ "$lang" = "pypy" ]; then
  run_cmd=(pypy3 main.py)
elif [ "$lang" = "cpp" ]; then
  g++ -std=gnu++23 -O1 -Wall -Wextra -o a.out main.cpp
  run_cmd=(./a.out)
  cleanup+=(a.out)
else
  echo "unknown lang: $lang" >&2
  exit 1
fi

# テスト
failed=0
i=0

for fin in tests/*.in; do
  [ -e "$fin" ] || {
    echo "no .in files"
    exit 1
  }
  i=$((i + 1))
  base="${fin%.in}"
  fout_expected="${base}.out"

  if [ ! -f "$fout_expected" ]; then
    echo "missing expected: $fout_expected" >&2
    failed=1
    continue
  fi

  out_actual="$(mktemp)"
  time_log="$(mktemp)"

  # 実行
  status=0
  if timeout 4s /usr/bin/time -f '%e' -o "$time_log" \
    "${run_cmd[@]}" <"$fin" >"$out_actual"; then
    status=0
  else
    status=$?
  fi

  if [ "$status" -ne 0 ]; then
    if [ "$status" -eq 124 ]; then
      printf "%s : %s (>4000 ms)\n" "$(style_tag TLE red)" "$(basename "$fin")"
    else
      printf "%s  : %s (exit=$status)\n" "$(style_tag RE red)" "$(basename "$fin")"
    fi
    failed=$((failed + 1))
    rm -f "$out_actual" "$time_log"
    continue
  fi

  elapsed="$(cat "$time_log")"
  elapsed_ms=$(awk "BEGIN { printf \"%.0f\", $elapsed * 1000 }")

  # 末尾改行差は無視して比較
  if diff -u <(awk '{print}' "$fout_expected") \
    <(awk '{print}' "$out_actual") >/dev/null; then
    printf "%s  : $(basename "$fin") (%d ms)\n" "$(style_tag AC green)" "$elapsed_ms"

  else
    printf "%s  : $(basename "$fin") (%d ms)\n" "$(style_tag WA red)" "$elapsed_ms"
    echo "--- expected ---"
    if [ -s "$fout_expected" ]; then
      cat "$fout_expected"
    else
      echo "<empty>"
    fi
    echo
    echo "---- actual ----"
    if [ -s "$out_actual" ]; then
      cat "$out_actual"
    else
      echo "<empty>"
    fi
    echo
    echo "---------------------------"
    echo
    failed=$((failed + 1))
  fi

  rm -f "$out_actual" "$time_log"
done

# 後始末
for f in "${cleanup[@]}"; do rm -f "$f"; done

if [ "$failed" -eq 0 ]; then
  printf "%s\n" "$(style_tag "ALL PASSED ($i tests)" green bold)"
  exit 0
else
  printf "%s\n" "$(style_tag "FAILED ($failed/$i tests failed)" red bold)"
  exit 0
fi
