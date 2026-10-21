# Phase 1: 最小の言語

整数・文字列・配列、変数、`if` / `while`、メソッド定義と呼び出し（括弧なしを含む）を、
lexer → parser → compiler → VM の全段階で動かす。

## 到達目標のサンプル

```ruby
# フィボナッチ
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

xs = [1, 2, 3]
puts len(xs)
puts xs[0] == 1

def hello
  puts "hello"
end
hello
```

## 字句（Lexer）

| 種類 | 内容 |
| --- | --- |
| 予約語 | `def` `end` `if` `elsif` `else` `while` `return` `true` `false` `nil` |
| 記号 | `= + - * / ! == != < > <= >= , ( ) [ ]` |
| リテラル | 整数 `123`、文字列 `"abc"`（エスケープ `\n` `\t` `\"` `\\`） |
| 識別子 | `[a-zA-Z_][a-zA-Z0-9_]*` |
| コメント | `#` から行末まで |
| 改行 | `NEWLINE` トークンとして出す（文の区切り）。`;` も同じ扱い |

### Token

```ruby
Token.new(type, literal, line:, column:, spaced:)
# line / column: 1 始まりの位置
# spaced: 直前に空白（改行・コメントを含む）があったか。括弧なし呼び出しの判定に使う
```

### 現状の lexer からの変更点

- 予約語 `let` を削除。
- `\n` を読み飛ばさず `NEWLINE` を出す（連続する改行や入力先頭の改行は1つにまとめる／出さない）。
  ただし次の改行は読み飛ばす（式を複数行に分けて書けるように）。
  - `( )` `[ ]` の中の改行
  - `,` `=` や二項演算子、前置 `!` の直後の改行
- 文字列、`[ ]`、`#` コメント、`nil` / `while` / `elsif` を追加。
- 識別子に数字を含められるようにする（`x1` など）。
- Token に `line` / `column` / `spaced` を持たせる。
- EOF で `ch = 0`（整数）を使っているのを `nil` に変える。
- `{ }` は Phase 1 では使わない（Phase 2 のハッシュ用に残す）。

## 構文（Parser）

### 文と式

`if` / `while` / `def` も含めて、すべて値を返す **式** として扱う（Ruby と同じ）。
プログラムは `NEWLINE` で区切られた文の並び。

```
program   = { stmt NEWLINE }
stmt      = command | expr
command   = IDENT cmd_args              # 括弧なし呼び出し（判定は下記）
cmd_args  = expr { "," expr }

expr      = def | if | while | return | assign | binary
assign    = IDENT "=" stmt
def       = "def" IDENT [ "(" [ IDENT { "," IDENT } ] ")" ] body "end"
if        = "if" stmt body { "elsif" stmt body } [ "else" body ] "end"
while     = "while" stmt body "end"
return    = "return" [ stmt ]
body      = { stmt NEWLINE }
```

括弧なし呼び出しを書けるのは、文の先頭・代入の右辺・`return` の値・`if` / `while` の条件。
二項演算の途中や、括弧なし呼び出しの引数の中には書けない（`puts len xs` は不可、`puts len(xs)` と書く）。

### 演算子の優先順位（低い順）

| 優先度 | 演算子 | 結合 |
| --- | --- | --- |
| 1 | `==` `!=` | 左 |
| 2 | `<` `>` `<=` `>=` | 左 |
| 3 | `+` `-` | 左 |
| 4 | `*` `/` | 左 |
| 5 | 前置 `!` `-` | 右 |
| 6 | 呼び出し `f(...)`、添字 `a[i]` | 左 |

二項演算は Pratt パーサ（演算子順位解析）で実装する。

### 識別子の解釈と括弧なし呼び出し

Ruby と同じく、**パーサがローカル変数の一覧を持つ**ことで曖昧さを解消する。

- パーサはスコープごとに「ここまでに代入された名前」の集合を持つ。
  代入 `x = ...` と `def` の仮引数で名前を追加し、`def` に入ると新しい集合を作る。
- 識別子がその集合に **含まれる** → ローカル変数。後ろに何が来ても変数として読む（`x - 1`、`x [0]` は演算と添字）。
- 識別子が集合に **含まれない** → メソッド呼び出し。次のトークンで書き方を決める。

| 書き方 | 解釈 | 判定 |
| --- | --- | --- |
| `foo` | `foo()` | 引数になれるトークンが続かない |
| `foo(1, 2)` | `foo(1, 2)` | `(` の直前に空白なし |
| `foo (1), 2` | `foo((1), 2)` | `(` の直前に空白あり → 括弧なし呼び出し |
| `foo 1, 2` | `foo(1, 2)` | 整数・文字列・識別子・`true` 等が続く |
| `foo [1]` | `foo([1])` | `[` の直前に空白あり |
| `foo[1]` | `foo()[1]` | `[` の直前に空白なし |
| `foo -1` | `foo(-1)` | `-` の前に空白あり・後ろに空白なし |
| `foo - 1` | `foo() - 1` | `-` の後ろに空白あり |
| `foo !x` | `foo(!x)` | `!` が続く |

この表の判定は、括弧なし呼び出しを書ける位置でだけ行う。それ以外の位置（二項演算の右辺など）では、
`foo (1)` も空白に関係なく括弧付き呼び出し、`foo [1]` は `foo()[1]` として読む。

同じ名前でも、代入より前に出てくれば呼び出し、後ろなら変数になる（Ruby と同じ挙動）。
代入の右辺を読む前に変数を宣言するので、`x = x` の右辺の `x` もローカル変数になる（値は nil）。

```ruby
puts x   # x はまだ代入されていない → x() の呼び出し（実行時エラー）
x = 1
puts x   # ローカル変数 x
```

### AST ノード

```
Program(body)
Assign(name, value)
Def(name, params, body)   Return(value)
If(cond, then, elsifs, else)   While(cond, body)
Call(name, args)          Index(target, index)
Infix(op, left, right)    Prefix(op, operand)
LocalVar(name)  IntLit  StrLit  BoolLit  NilLit  ArrayLit(elements)
```

`Call` は括弧付き・括弧なし・0引数の区別を持たない（パース時に同じ形にそろえる）。

パーサのテストは AST を S 式風の文字列にして比較する（例: `(+ 1 (* 2 3))`、`(call puts (lvar x))`）。

### 構文エラー

最初に見つけたエラーで `Belial::Parser::ParseError` を投げる。メッセージは `行:列: 内容` の形
（例: `1:6: expected NEWLINE, got end of input`）。ファイル名付きの表示は Phase 2 で行う。

## 意味論

- **値**: Integer / String / true・false / nil / Array / Function。
- **真偽**: `false` と `nil` だけが偽（Ruby と同じ）。
- **変数**: 最初の代入で宣言される。宣言用のキーワードはない。
- **スコープ**: トップレベルとメソッドごとにローカルスコープ。
  メソッドからトップレベルの変数は見えない（クロージャは Phase 2）。
  `if` / `while` は新しいスコープを作らない。
- **メソッド**: 最後に評価した式の値が戻り値。`return` で途中で抜けられる。再帰呼び出しができる。
  定義はトップレベルのみ（メソッドの中で `def` は書けない）。
- **組み込み関数**: `puts`、`p`、`len`、`push(arr, x)`。
- **エラー**: 未定義メソッドの呼び出し、引数の数の不一致、型の合わない演算は実行時エラーで停止する。

## バイトコード

### ISeq（命令列オブジェクト）

```ruby
ISeq = Struct.new(:name, :params, :locals, :insns)
# name:   "main" や メソッド名
# params: 引数の数
# locals: ローカル変数名の表（index = 変数スロット番号。先頭 params 個は引数）
# insns:  [[:putobject, 1], [:getlocal, 0], ...]
```

### 命令セット

YARV の命令名を参考にしつつ、単純化する。

| 命令 | オペランド | スタック変化 | 説明 |
| --- | --- | --- | --- |
| `putobject` | 値 | → v | 定数を積む |
| `putnil` | | → nil | |
| `pop` | | v → | |
| `dup` | | v → v v | |
| `getlocal` | idx | → v | ローカル変数を積む |
| `setlocal` | idx | v → | ローカル変数に代入 |
| `add` `sub` `mul` `div` | | a b → r | 算術 |
| `eq` `neq` `lt` `gt` `le` `ge` | | a b → bool | 比較 |
| `not` `neg` | | a → r | 前置演算 |
| `newarray` | n | v1..vn → arr | 配列生成 |
| `index` | | arr i → v | 添字アクセス |
| `jump` | addr | | 無条件ジャンプ |
| `branchunless` | addr | v → | 偽ならジャンプ |
| `definemethod` | name, iseq | → nil | メソッドを登録 |
| `send` | name, argc | args → r | メソッド／組み込み関数呼び出し |
| `leave` | | v → | 現在のフレームから戻る |

括弧なし呼び出しも0引数呼び出しも、コンパイル後はすべて `send` になる（`hello` → `send :hello 0`）。

`def` の本体は別の ISeq にコンパイルし、`definemethod` で実行時に登録する（`def` 自体の値は nil）。
そのため、メソッドは `def` を実行した後でないと呼べない。
`return` は値を積んでその場で `leave` する。`disasm` ではメソッドの ISeq も main の後ろに続けて表示する。

### コンパイル例

```ruby
a = 1
if a < 2
  puts "small"
end
```

```
== main
0000 putobject 1
0001 dup
0002 setlocal 0        # a
0003 pop
0004 getlocal 0
0005 putobject 2
0006 lt
0007 branchunless 11
0008 putobject "small"
0009 send :puts 1
0010 jump 12
0011 putnil
0012 leave
```

- 代入も式なので、値を `dup` してから `setlocal` する。文の値として使わなければ直後の `pop` で捨てる。
- `if` / `while` のジャンプ先は、先に `nil` で命令を出しておき、飛び先が決まったら埋める（バックパッチ）。
- `else` のない `if` で条件が偽のときの値は `nil`。`while` 自体の値は常に `nil`。

`while` は次の形になる。

```
COND:
  条件
  branchunless END
  本体
  pop
  jump COND
END:
  putnil
```

## VM

- 値スタックは1本。フレーム `Frame(iseq, pc, bp)` をコールスタックに積む。
- `bp`（ベースポインタ）から `locals.size` 個のスロットをローカル変数領域として確保する。
  `send` では積まれた引数がそのまま呼び出し先のローカル変数 0〜argc-1 になる。
- `send` は ユーザー定義メソッド → 組み込み関数 の順に名前を探す。
- `send` は新しいフレームを積むだけで、実行は同じループのまま呼び出し先の命令に進む
  （Ruby 自体の再帰呼び出しは使わない）。
- 定義されていないメソッドの呼び出しは `undefined method 'foo'`、
  引数の数が合わなければ `wrong number of arguments for 'f' (given 2, expected 1)` で停止する。
- フレームが 10,000 段を超えたら `stack level too deep` で停止する（無限再帰の検出）。

### メソッド呼び出しの流れ

```ruby
def add(a, b)
  c = a + b
end
add(1, 2)
```

```
add の ISeq: params 2, locals [a, b, c]

send :add 2 の直前      [ 1, 2 ]
                          ↑ bp（積まれた引数の先頭）
フレームを積んだ直後    [ 1, 2, nil ]        a=1, b=2, c=nil（引数以外のローカル変数を nil で確保）
leave の直前            [ 1, 2, 3, 3 ]       c=3、スタックの先頭が戻り値
leave の直後            [ 3 ]                bp から上を捨てて戻り値を積む
```
- `leave` で戻り値を取り出し、スタックを `bp` まで巻き戻して戻り値を積み直す。
- `-d` オプションで命令ごとのスタックを表示する（既存 VM のデバッグモードと同じ）。
- `--disasm` オプションで ISeq を表示する（`ISeq#disasm`）。
- 整数の割り算は Ruby と同じく負の無限大方向に切り捨てる（`-7 / 2` は `-4`）。
- `==` / `!=` はどの値どうしでも比べられる（`1 == true` は false）。
  `< > <= >=` と算術演算は整数どうしのみ。
- 0 での割り算や、整数以外への算術演算・大小比較は `Belial::VM::VMError` で停止する。
- まだコンパイルできないノードは `Belial::Compiler::CompileError`（例: `Assign is not supported yet`）。

### 呼び出し口

```ruby
require_relative 'lib/belial'
Belial.compile(source)              # => ISeq
Belial.run(source, debug: false)    # => 最後に評価した式の値
```

## 実装ステップ

- [x] 1. lexer の完成（上記の変更点）とテストの更新
- [x] 2. パーサと AST（式 → 代入 → `if` / `while` → `def` / 呼び出し → 括弧なし呼び出し）
- [x] 3. コンパイラと VM: 整数の四則演算
- [x] 4. 変数、比較、`if` / `while`
- [x] 5. メソッド定義・呼び出し・`return`・再帰
- [ ] 6. 文字列・配列・組み込み関数、実行コマンド `bin/belial` と REPL
- [x] 7. 既存の YARV 実行器を `lib/belial/yarv/` へ移動（`Belial::YARV::VM`。新しい VM と名前がぶつかるため 3 と一緒に実施）
