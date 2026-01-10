# atcoder-workspace

## Directory Structure
```
atcoder-workspace
  ├── scripts/
  │   |-- acc             # 競プロ用スクリプト（@ホスト環境）
  │   |-- cc_server.py    # Competitive Companion からのデータ受信サーバー
  │   |-- dev.sh          # Docker 起動スクリプト
  │   |-- run_tests.sh    # テスト実行スクリプト（@コンテナ環境）
  ├── template/           # 競プロコードテンプレート
  ├── docker-compose.yml
  ├── Dockerfile
  └── README.md
```

`acc` コマンドにより、コンテナ起動やテスト実行を含むすべての操作を **ホスト環境** から行います。

## Requirement

- [Competitive Companion](https://github.com/jmerle/competitive-companion)
  - ブラウザ拡張機能としてインストール

## Usage
準備中

### Python 仮想環境（venv）運用
- コンテナ作成後に `/workspace/.venv` を自動作成し、`pip`/`pylint` を導入します（devcontainer の `postCreateCommand`）。
- VS Code は `python.defaultInterpreterPath` を `/workspace/.venv/bin/python` に設定済みです。
- テスト実行スクリプトは venv が存在すればそれを優先して実行します（`scripts/run_tests.sh`）。
- 端末で手動利用する場合は、必要に応じて下記で有効化してください：

```bash
source /workspace/.venv/bin/activate
python --version
```
```
```
