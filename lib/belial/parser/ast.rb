module Belial
  # 構文木のノード。to_sexp でテスト用の S 式風の文字列にする
  module AST
    def self.sexp(*items)
      "(#{items.join(' ')})"
    end

    def self.body_sexp(body)
      sexp("body", *body.map(&:to_sexp))
    end

    Program = Struct.new(:body) do
      def to_sexp
        body.map(&:to_sexp).join("\n")
      end
    end

    Assign = Struct.new(:name, :value) do
      def to_sexp
        AST.sexp("=", name, value.to_sexp)
      end
    end

    Def = Struct.new(:name, :params, :body) do
      def to_sexp
        AST.sexp("def", name, AST.sexp("params", *params), AST.body_sexp(body))
      end
    end

    # value が nil なら値なしの return
    Return = Struct.new(:value) do
      def to_sexp
        value ? AST.sexp("return", value.to_sexp) : AST.sexp("return")
      end
    end

    # elsifs: [[条件, 本体], ...]、else_body: なければ nil
    If = Struct.new(:cond, :then_body, :elsifs, :else_body) do
      def to_sexp
        parts = ["if", cond.to_sexp, AST.body_sexp(then_body)]
        elsifs.each do |c, b|
          parts << AST.sexp("elsif", c.to_sexp, AST.body_sexp(b))
        end
        parts << AST.sexp("else", AST.body_sexp(else_body)) if else_body
        AST.sexp(*parts)
      end
    end

    While = Struct.new(:cond, :body) do
      def to_sexp
        AST.sexp("while", cond.to_sexp, AST.body_sexp(body))
      end
    end

    # 括弧付き・括弧なし・0引数の呼び出しはすべてこの形になる
    Call = Struct.new(:name, :args) do
      def to_sexp
        AST.sexp("call", name, *args.map(&:to_sexp))
      end
    end

    Index = Struct.new(:target, :index) do
      def to_sexp
        AST.sexp("index", target.to_sexp, index.to_sexp)
      end
    end

    Infix = Struct.new(:op, :left, :right) do
      def to_sexp
        AST.sexp(op, left.to_sexp, right.to_sexp)
      end
    end

    Prefix = Struct.new(:op, :operand) do
      def to_sexp
        AST.sexp(op, operand.to_sexp)
      end
    end

    LocalVar = Struct.new(:name) do
      def to_sexp
        AST.sexp("lvar", name)
      end
    end

    IntLit = Struct.new(:value) do
      def to_sexp
        value.to_s
      end
    end

    StrLit = Struct.new(:value) do
      def to_sexp
        value.inspect
      end
    end

    BoolLit = Struct.new(:value) do
      def to_sexp
        value.to_s
      end
    end

    class NilLit
      def to_sexp
        "nil"
      end

      def ==(other)
        other.is_a?(NilLit)
      end
    end

    ArrayLit = Struct.new(:elements) do
      def to_sexp
        AST.sexp("array", *elements.map(&:to_sexp))
      end
    end
  end
end
