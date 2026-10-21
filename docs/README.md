# Belial 設計資料

## 方針

- **目的**: 処理系の仕組み（字句解析 → 構文解析 → コンパイル → VM）を一通り自作して学ぶ。
  言語仕様は小さく保ち、各段階の実装を理解しやすくすることを優先する。
- **構文**: Ruby 風（`def ... end`、`if ... end`、括弧なし呼び出し）。
- **型**: 動的型付け。
- **実行方式**: AST を自作バイトコードにコンパイルし、自作のスタック VM で実行する。

```
ソース ─▶ Lexer ─▶ Token列 ─▶ Parser ─▶ AST ─▶ Compiler ─▶ ISeq ─▶ VM
```

## フェーズ

| フェーズ | 資料 | 内容 |
| --- | --- | --- |
| Phase 1（実装済み） | [phase1.md](phase1.md) | 最小の言語: 整数・文字列・配列、変数、`if` / `while`、メソッド、括弧なし呼び出し |
| Phase 2 | [phase2.md](phase2.md) | 表現力: 式展開、ハッシュ、ブロックとクロージャ、エラー位置の表示 |
| Phase 3 | [phase3.md](phase3.md) | オブジェクト: `.` によるメソッド呼び出し、クラス、簡単な最適化 |

各フェーズの資料には、そのフェーズで追加する字句・構文・意味論・命令・VM の変更をまとめる。
後のフェーズは前のフェーズの仕様を前提とする。

## ディレクトリ構成

```
lib/belial.rb # Belial.compile / Belial.run
lib/belial/
  lexer/      token.rb, lexer.rb, lexical_analyzer.rb
  parser/     parser.rb, ast.rb
  compiler/   compiler.rb, iseq.rb
  vm/         vm.rb, frame.rb, builtins.rb
  repl.rb
  yarv/       vm.rb   # 既存の YARV 実行器（参考実装として残す。boot / disasm から使う）
bin/belial    # 実行コマンド（belial file.bl / -e / -d / --disasm / 引数なしで REPL）
examples/     # サンプルプログラム（.bl）
docs/         # 設計資料
test/         # lexers / parser / compiler / vm / repl / cli
```

- ソースの拡張子は `.bl`。
- `require` は `require_relative` に統一し、どこからでもテストを実行できるようにする。

## 決定記録

| 日付 | 決定 | 理由 |
| --- | --- | --- |
| 2026-10-21 | 目的は「処理系の仕組みを学ぶ」 | 仕様より実装の理解を優先する |
| 2026-10-21 | 構文は Ruby 風（`def` / `end`） | 既存 lexer の予約語を活かす |
| 2026-10-21 | AST → 自作バイトコード → 自作 VM | 既存の YARV 実行器の経験を活かし、コンパイラも自作する |
| 2026-10-21 | 動的型付け | 実装を単純に保つ |
| 2026-10-21 | `let` を廃止し、最初の代入で変数を宣言する | Ruby と同じ書き味にする |
| 2026-10-21 | 括弧なし呼び出し（`puts x`）を Phase 1 から使えるようにする | Ruby 風の書き味を最初から得る。曖昧さの解消方法も学習対象にする |
| 2026-10-21 | 既存の YARV 実行器は `lib/belial/yarv/` に残す | 自作 VM を作る際の参考にする |
