# Phase 2: 表現力

Phase 1 の言語に、文字列の式展開・ハッシュ・ブロックとクロージャ・ループ制御・エラー位置の表示を加える。
この資料は方針の段階で、Phase 1 の完了後に詳細を詰める。

## 到達目標のサンプル

```ruby
name = "belial"
puts "hello, #{name}! #{1 + 2}"

ages = { "alice" => 20, "bob" => 30 }
puts ages["alice"]

total = 0
each [1, 2, 3] do |x|
  total = total + x     # ブロックの外の変数を書き換えられる
end
puts total              # => 6

def twice
  yield
  yield
end
twice do
  puts "hi"
end

i = 0
while true
  i = i + 1
  if i == 3
    next
  end
  if i > 5
    break
  end
  puts i
end
```

## 文字列の式展開 `"#{...}"`

- lexer にモードのスタックを持たせる。文字列の中で `#{` を見たら通常モードに入り、
  対応する `}` で文字列モードに戻る（`{ }` の深さを数える）。
- トークン: `STRING_BEG` `STRING_PART` `INTERP_BEG` `INTERP_END` `STRING_END`。
- AST: `InterpolatedStr(parts)`。parts は `StrLit` と式の並び。
- 命令: `tostring`（v → 文字列）と `concatstrings n`（既存 YARV 実行器の経験を活かす）。

## ハッシュ

- リテラル `{ key => value, ... }`。キーは任意の値。
- 添字 `h[k]` の読み出しと `h[k] = v` の代入。配列にも `a[i] = v` を追加する。
- 命令: `newhash n`、`setindex`。
- 組み込み関数: `keys(h)`、`has_key(h, k)`。
- `{` はハッシュ専用（ブロックは `do ... end` のみ）にして、構文の曖昧さを避ける。

## ブロックとクロージャ

- 呼び出しの後ろに `do |params| ... end` を付けられる（括弧付き・括弧なし両方）。
- メソッドの中で `yield args` によりブロックを呼ぶ。`block_given` で有無を確認できる。
- ブロックは外側のローカル変数を読み書きできる（クロージャ）。
- 組み込み関数: `each(arr)`、`map(arr)`、`select(arr)`。

### 実装方針

- ブロックは独自の ISeq を持ち、外側の ISeq を `parent` として参照する。
- ローカル変数の命令をスコープの深さ付きにする: `getlocal idx, level` / `setlocal idx, level`
  （level 0 = 自分、1 = 1つ外側。YARV と同じ考え方）。
- フレームに `ep`（環境ポインタ）を持たせ、外側の環境へたどれるようにする。
- ブロックが外側のメソッドより長く生き残る場合（後で呼ぶために保存する場合）に備え、
  ブロックに捕捉された環境はスタックではなくヒープ上のオブジェクトに置く。
  どの変数が捕捉されるかはコンパイル時に判定する。
- 命令: `send name, argc, block_iseq`（ブロック付き呼び出し）、`invokeblock argc`（`yield`）。

## ループ制御

- `break` / `next` を `while` の中で使えるようにする。コンパイル時に `jump` に変換する。
- ブロックの中の `break` / `next` は Phase 2 では対象外（必要になったら検討する）。

## エラー位置の表示

- AST ノードに行番号を持たせる。
- ISeq に「命令番号 → 行番号」の表を持たせる。
- 構文エラーは `file.bl:3:5: unexpected token ...`、実行時エラーは `file.bl:10: undefined method 'foo'` の形で表示する。
- 実行時エラーではコールスタックをさかのぼって表示する（バックトレース）。

## 未決事項

- [ ] ブロックの中の `break` / `next` を扱うか
- [ ] 文字列の追加メソッド（`split`、`upcase` など）を組み込み関数で用意するか、Phase 3 の `.` 呼び出しまで待つか
