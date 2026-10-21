# Belial

[![CI](https://github.com/723gt/belial/actions/workflows/ci.yaml/badge.svg)](https://github.com/723gt/belial/actions/workflows/ci.yaml)

処理系の仕組みを学ぶために作っている、Ruby 風の小さなプログラミング言語です。
字句解析器・構文解析器・バイトコードコンパイラ・スタック VM を、すべて Ruby で自作しています。

```ruby
def fib(n)
  if n < 2
    return n
  end
  fib(n - 1) + fib(n - 2)
end

i = 0
while i < 10
  puts fib(i)
  i = i + 1
end
```

## 必要なもの

- Ruby 3.3（`.ruby-version` は 3.3.6）
- gem のインストールは不要です

## 使い方

```sh
ruby bin/belial examples/phase1.bl       # ファイルを実行
ruby bin/belial -e 'puts 1 + 2'          # 引数のコードを実行
ruby bin/belial                          # REPL を起動
```

### REPL

```
belial> def add(a, b)
   ...>   a + b
   ...> end
=> nil
belial> x = 5
=> 5
belial> add x, 2
=> 7
```

`def` や `if` が閉じるまで続きの行を読みます。`exit`、`quit`、Ctrl-D で終了します。

### 中身を見る

`--disasm` で、実行せずにコンパイル結果の命令列を表示します。

```
$ ruby bin/belial --disasm -e 'x = 1 + 2'
== main
0000 putobject 1
0001 putobject 2
0002 add
0003 dup
0004 setlocal 0
0005 leave
```

`-d` で、命令を1つ実行するごとにスタックの中身を標準エラーに表示します。

```
$ ruby bin/belial -d -e '1 + 2'
0000 putobject 1
     stack: [1]
0001 putobject 2
     stack: [1, 2]
0002 add
     stack: [3]
0003 leave
```

## 言語の概要（Phase 1）

```ruby
# 変数は最初の代入で宣言する（宣言用のキーワードはない）
name = "belial"
puts "hello, " + name

# 配列
xs = [3, 1, 2]
push xs, 4
puts len(xs)        # => 4
puts xs[0] == 3     # => true

# if / while も値を返す式
def max(a, b)
  if a > b
    a
  else
    b
  end
end
puts max(3, 7)      # => 7
```

- **値**: 整数、文字列、`true` / `false`、`nil`、配列
- **真偽**: `false` と `nil` だけが偽（Ruby と同じ）
- **演算子**: `+ - * /`、`== != < > <= >=`、前置の `!` と `-`、添字 `a[i]`
- **制御構文**: `if` / `elsif` / `else`、`while`
- **メソッド**: `def ... end`、`return`、再帰。メソッドの中からトップレベルの変数は見えません
- **括弧なし呼び出し**: Ruby と同じく `puts x` と書けます。`foo -1` は `foo(-1)`、`foo - 1` は引き算のように、空白の有無で区別します
- **組み込み関数**

  | 関数 | 動作 |
  | --- | --- |
  | `puts(...)` | 引数を1つずつ行に出力 |
  | `p(...)` | inspect した形で出力し、引数を返す |
  | `len(x)` | 配列・文字列の長さ |
  | `push(arr, x)` | 配列の末尾に追加 |

詳しい仕様は [docs/phase1.md](docs/phase1.md) にあります。

## 仕組み

```
ソース ─▶ Lexer ─▶ Token列 ─▶ Parser ─▶ AST ─▶ Compiler ─▶ ISeq（命令列）─▶ VM
```

| 段階 | 場所 | 内容 |
| --- | --- | --- |
| 字句解析 | `lib/belial/lexer/` | ソースをトークンに分ける。改行は文の区切りになる |
| 構文解析 | `lib/belial/parser/` | Pratt パーサで AST を作る。変数かメソッド呼び出しかもここで決める |
| コンパイル | `lib/belial/compiler/` | AST をスタックマシンの命令列（ISeq）に変換する |
| 実行 | `lib/belial/vm/` | 値スタックとフレームで命令列を実行する |

命令は `putobject`、`getlocal` / `setlocal`、`add`、`lt`、`branchunless`、`jump`、`send`、`leave` など25個です。
Ruby の YARV の命令名を参考にしています。

Ruby のコードからも使えます。

```ruby
require_relative 'lib/belial'

Belial.run('1 + 2 * 3')             # => 7
puts Belial.compile('1 + 2').disasm
```

## ディレクトリ構成

```
bin/belial        実行コマンド
lib/belial.rb     Belial.compile / Belial.run
lib/belial/       lexer / parser / compiler / vm / repl.rb
lib/belial/yarv/  Ruby の YARV 命令列を実行する実験的な VM（boot / disasm から使う）
examples/         サンプルプログラム（.bl）
docs/             設計資料
test/             テスト
```

## テスト

```sh
rake test
```

GitHub Actions が、`main` への push とプルリクエストのたびに同じテストを実行します。

## ロードマップ

| フェーズ | 内容 | 状態 |
| --- | --- | --- |
| [Phase 1](docs/phase1.md) | 整数・文字列・配列、変数、`if` / `while`、メソッド、括弧なし呼び出し、REPL | 実装済み |
| [Phase 2](docs/phase2.md) | 文字列の式展開、ハッシュ、ブロックとクロージャ、`break` / `next`、エラー位置の表示 | 予定 |
| [Phase 3](docs/phase3.md) | `.` によるメソッド呼び出し、クラス、簡単な最適化 | 予定 |

設計の方針と決定の記録は [docs/README.md](docs/README.md) にあります。
