#!/usr/bin/env bash
set -euo pipefail

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
  run_cmd=(python3 main.py)
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
      echo "TLE : $(basename "$fin") (>4000 ms)"
    else
      echo "RE  : $(basename "$fin") (exit=$status)"
      failed=$((failed + 1))
    fi
    rm -f "$out_actual" "$time_log"
    continue
  fi

  elapsed="$(cat "$time_log")"
  elapsed_ms=$(awk "BEGIN { printf \"%.0f\", $elapsed * 1000 }")

  # 末尾改行差は無視して比較
  if diff -u <(sed -e 's/[[:space:]]*s//' "$fout_expected") \
    <(sed -e 's/[[:space:]]*s//' "$out_actual") >/dev/null; then
    printf "OK  : $(basename "$fin") (%d ms)\n" "$elapsed_ms"

  else
    printf "WA  : $(basename "$fin") (%d ms)\n" "$elapsed_ms"
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
  echo "ALL PASSED ($i tests)"
  exit 0
else
  echo "SOME FAILED ($failed tests)"
  exit 0
fi
