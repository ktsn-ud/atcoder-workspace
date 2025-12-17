import json
import os
import re
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlparse

WORKDIR = os.environ.get("AC_WORKDIR", "/workspace/contests")
PORT = int(os.environ.get("CC_PORT", 10043))

# AtCoderの問題ページURLからcontest_idとtask_idを取得するための正規表現
ATCODER_TASK_RE = re.compile(r"^/contests/([^/]+)/tasks/([^/]+)$")
TEMPLATE_DIR = "/workspace/template"


def comment_prefix_for(path: str) -> str:
    if path.endswith("py"):
        return "# "
    if path.endswith("cpp"):
        return "// "
    raise ValueError(f"Unknown file type: {path}")


def copy_template_with_header_if_not_exists(src: str, dst: str, url: str):
    if os.path.exists(dst):
        return

    prefix = comment_prefix_for(dst)
    header = f"{prefix}{url}\n\n"

    with open(src, "r", encoding="utf-8") as rf:
        content = rf.read()
    with open(dst, "w", encoding="utf-8", newline="\n") as wf:
        wf.write(header)
        wf.write(content)


def ensure_problem_dir(contest_id: str, task_id: str, url: str) -> str:
    dir = os.path.join(WORKDIR, contest_id, task_id)
    os.makedirs(os.path.join(dir, "tests"), exist_ok=True)

    copy_template_with_header_if_not_exists(
        os.path.join(TEMPLATE_DIR, "main.py"), os.path.join(dir, "main.py"), url
    )

    copy_template_with_header_if_not_exists(
        os.path.join(TEMPLATE_DIR, "main.cpp"), os.path.join(dir, "main.cpp"), url
    )

    return dir


def write_tests(problem_dir: str, tests: list[dict]) -> int:
    tests_dir = os.path.join(problem_dir, "tests")
    test_count = 0
    for i, t in enumerate(tests, start=1):
        inp = t.get("input", "")
        out = t.get("output", "")
        in_path = os.path.join(tests_dir, f"sample-{i}.in")
        out_path = os.path.join(tests_dir, f"sample-{i}.out")
        with open(in_path, "w", encoding="utf-8") as f:
            f.write(inp)
        with open(out_path, "w", encoding="utf-8") as f:
            f.write(out)
        test_count += 1
    return test_count


def parse_atcoder_ids(url: str) -> tuple[str, str]:
    u = urlparse(url)
    mat = ATCODER_TASK_RE.match(u.path)
    if not mat:
        raise ValueError(f"Unsupported url path: {u.path}")
    return mat.group(1), mat.group(2)


class Handler(BaseHTTPRequestHandler):
    def do_POST(self):
        try:
            length = int(self.headers.get("Content-Length", "0"))
            raw = self.rfile.read(length).decode("utf-8")
            payload = json.loads(raw)

            if isinstance(payload, list):
                if not payload:
                    raise ValueError("Empty payload list")
                payload = payload[0]  # 最初の一つのみ
            if not isinstance(payload, dict):
                raise ValueError("Payload is not an object")

            url = payload.get("url")
            tests = payload.get("tests", [])
            if not isinstance(url, str):
                raise ValueError("Missing URL")
            if not isinstance(tests, list):
                raise ValueError("Tests must be a list")

            contest_id, task_id = parse_atcoder_ids(url)
            problem_dir = ensure_problem_dir(contest_id, task_id, url)
            n_tests = write_tests(problem_dir, tests)

            msg = {
                "ok": True,
                "contest_id": contest_id,
                "task_id": task_id,
                "dir": problem_dir,
                "tests": n_tests,
            }
            body = json.dumps(msg).encode("utf-8")

            self.send_response(200)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            print("[cc] created:", problem_dir)
            print("[cc] number of test(s):", n_tests)

        except Exception as e:
            body = json.dumps({"ok": False, "error": str(e)}).encode("utf-8")
            self.send_response(400)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            print("[cc] error:", e)

    def log_message(self, format, *args):
        return


def main():
    os.makedirs(WORKDIR, exist_ok=True)
    server = HTTPServer(("0.0.0.0", PORT), Handler)
    print(f"[cc] listening on 0.0.0.0:{PORT} (workdir={WORKDIR})")
    server.serve_forever()


if __name__ == "__main__":
    main()
