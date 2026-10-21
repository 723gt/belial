# Phase 3: オブジェクト

レシーバ付きのメソッド呼び出し（`.`）とクラスを加え、オブジェクト指向の言語にする。
最後に、VM の簡単な最適化を行う。
この資料は方針の段階で、Phase 2 の完了後に詳細を詰める。

## 到達目標のサンプル

```ruby
class Counter
  def initialize(start)
    @count = start
  end

  def up
    @count = @count + 1
  end

  def count
    @count
  end
end

c = Counter.new(10)
c.up
c.up
puts c.count            # => 12

xs = [3, 1, 2]
puts xs.len
xs.each do |x|
  puts x * 2
end
5.times do |i|
  puts i
end
```

## メソッド呼び出し構文 `recv.meth`

- `recv.meth(args)`、`recv.meth args`（括弧なし）、`recv.meth do ... end` を書けるようにする。
- 組み込み型（Integer / String / Array / Hash）にメソッドを持たせる。
  Phase 1・2 の組み込み関数（`len(xs)` など）は `xs.len` に置き換え、関数版は互換のため残すか検討する。
- レシーバのない呼び出し（`puts x`）は `self` へのメソッド呼び出しとして扱う。
  トップレベルの `self` は `main` オブジェクト（既存 YARV 実行器の `generate_main` と同じ考え方）。

## クラス

- `class Name ... end` でクラスを定義する。`class Dog < Animal` で継承する。
- `Name.new(args)` でインスタンスを作り、`initialize` を呼ぶ。
- インスタンス変数 `@name`。`self` で自分自身を参照する。
- 定数（大文字で始まる識別子）を lexer で区別する: `CONSTANT` トークン。
- クラスを後から開き直してメソッドを追加できる（オープンクラス）。

### 実装方針

- オブジェクトモデル: `BClass(name, superclass, methods)`、`BObject(klass, ivars)`。
  組み込み型もそれぞれ `BClass` を持ち、メソッド探索を共通化する。
- メソッド探索: レシーバのクラス → スーパークラス → … の順に探す。
- `send` はスタックからレシーバも取り出すように変える（`recv args → r`）。
  Phase 1 で積んでいなかったレシーバは、コンパイラが `putself` を出して補う。
- フレームに `self` を持たせる。
- 命令: `putself`、`getconstant`、`setconstant`、`defineclass name, iseq`、
  `getinstancevariable name`、`setinstancevariable name`。

## 最適化

処理系の高速化の考え方を学ぶため、効果を測りながら少しずつ入れる。

- **ベンチマーク**: `fib(25)` などで実行時間を計測する仕組みを先に作る。
- **定数畳み込み**: `1 + 2` をコンパイル時に `3` にする。
- **のぞき穴最適化**: `jump` 先がまた `jump` の場合の短絡など、命令列を後処理で整理する。
- **特化命令**: `opt_plus` などで Integer 同士の場合だけ速い経路を通す。
- **インラインメソッドキャッシュ**: `send` 命令ごとに前回のクラスと探索結果を覚えておく。

## 未決事項

- [ ] 組み込み関数（`len(xs)` など）を `.` 呼び出しに一本化するか、両方残すか
- [ ] モジュール／ミックスインを扱うか
