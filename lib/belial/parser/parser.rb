require 'set'
require_relative '../lexer/lexical_analyzer'
require_relative 'ast'

module Belial
  module Parser
    class ParseError < StandardError
      # 入力の終わりで起きたエラーか。REPL で「続きの行を読む」かの判定に使う
      def initialize(message, at_eof: false)
        super(message)
        @at_eof = at_eof
      end

      def at_eof?
        @at_eof
      end
    end

    # Pratt パーサ（演算子順位解析）。
    # @cur は「まだ消費していない次のトークン」を指す。各 parse_* は自分の読んだ範囲の
    # 次のトークンまで @cur を進めて返る
    class Parser
      include Belial::Lexer

      LOWEST      = 0
      EQUALS      = 1 # == !=
      LESSGREATER = 2 # < > <= >=
      SUM         = 3 # + -
      PRODUCT     = 4 # * /
      PREFIX      = 5 # !x -x
      INDEX       = 6 # a[i]

      PRECEDENCES = {
        EQ => EQUALS, NOT_EQ => EQUALS,
        LT => LESSGREATER, GT => LESSGREATER, LTQ => LESSGREATER, GTQ => LESSGREATER,
        PLUS => SUM, MINUS => SUM,
        ASTERISK => PRODUCT, SLASH => PRODUCT,
        LBRACKET => INDEX
      }

      # 括弧なし呼び出しの最初の引数になれるトークン（( [ - は空白の有無で別に判定する）
      COMMAND_ARG_START = [INT, STRING, IDENT, TRUE, FALSE, NIL, BANG]

      # if / while / def の本体の終わりを表すトークン
      BODY_END = [T_END, ELSE, ELSIF]

      # locals: すでにあるトップレベルの変数（REPL で前の入力の変数を変数として読むため）
      def initialize(input, locals: [])
        @analyzer = LexicalAnalyzer.new(input)
        @analyzer.createLexer
        @tokens = [] # 先読みしたトークン
        @cur = @analyzer.nextToken
        # スコープごとの「ここまでに代入された名前」。ローカル変数かメソッド呼び出しかの判定に使う
        @scopes = [Set.new(locals)]
      end

      def parse_program
        body = parse_body([])
        expect(EOF)
        AST::Program.new(body)
      end

      private

      # ---- トークン操作 ----

      # @cur を消費して返し、次のトークンに進む
      def advance
        token = @cur
        @cur = @tokens.empty? ? @analyzer.nextToken : @tokens.shift
        token
      end

      # @cur の n 個先のトークン
      def peek(n = 1)
        @tokens << @analyzer.nextToken while @tokens.size < n
        @tokens[n - 1]
      end

      def expect(type)
        error("expected #{type}, got #{describe(@cur)}") unless @cur.type == type
        advance
      end

      def skip_newlines
        advance while @cur.type == NEWLINE
      end

      def error(message)
        raise ParseError.new("#{@cur.line}:#{@cur.column}: #{message}", at_eof: @cur.type == EOF)
      end

      def describe(token)
        case token.type
        when EOF then "end of input"
        when NEWLINE then "newline"
        else "'#{token.literal}'"
        end
      end

      # ---- スコープ ----

      def local?(name)
        @scopes.last.include?(name)
      end

      def declare(name)
        @scopes.last << name
      end

      # ---- 文 ----

      # terminators のどれか（または EOF）が来るまで文を読む。terminators 自体は消費しない
      def parse_body(terminators)
        body = []
        skip_newlines
        until @cur.type == EOF || terminators.include?(@cur.type)
          body << parse_stmt
          unless @cur.type == NEWLINE || @cur.type == EOF || terminators.include?(@cur.type)
            error("unexpected #{describe(@cur)}")
          end
          skip_newlines
        end
        body
      end

      # 文の先頭・代入の右辺・return の値・if / while の条件。括弧なし呼び出しを書ける位置
      def parse_stmt
        parse_expression(LOWEST, command: true)
      end

      # ---- 式 ----

      def parse_expression(precedence, command: false)
        return parse_command_call if command && command_call?

        left = parse_prefix
        while PRECEDENCES.fetch(@cur.type, LOWEST) > precedence
          left = parse_infix(left)
        end
        left
      end

      def parse_prefix
        case @cur.type
        when INT
          AST::IntLit.new(advance.literal.to_i)
        when STRING
          AST::StrLit.new(advance.literal)
        when TRUE
          advance
          AST::BoolLit.new(true)
        when FALSE
          advance
          AST::BoolLit.new(false)
        when NIL
          advance
          AST::NilLit.new
        when IDENT
          parse_identifier
        when LPAREN
          parse_grouped
        when LBRACKET
          advance
          AST::ArrayLit.new(parse_list(RBRACKET))
        when BANG, MINUS
          op = advance.literal
          AST::Prefix.new(op, parse_expression(PREFIX))
        when IF
          parse_if
        when WHILE
          parse_while
        when METHOD
          parse_def
        when RETURN
          parse_return
        else
          error("unexpected #{describe(@cur)}")
        end
      end

      def parse_infix(left)
        op = advance
        if op.type == LBRACKET
          index = parse_expression(LOWEST)
          expect(RBRACKET)
          return AST::Index.new(left, index)
        end
        AST::Infix.new(op.literal, left, parse_expression(PRECEDENCES[op.type]))
      end

      # 代入・ローカル変数・括弧付き呼び出し・0引数呼び出し
      def parse_identifier
        return parse_assign if peek.type == ASSIGN

        name = advance.literal
        return AST::LocalVar.new(name) if local?(name)

        if @cur.type == LPAREN
          advance
          return AST::Call.new(name, parse_list(RPAREN))
        end
        AST::Call.new(name, [])
      end

      def parse_assign
        name = advance.literal
        advance # =
        # Ruby と同じく、右辺を読む前に宣言する（x = x の右辺の x もローカル変数）
        declare(name)
        AST::Assign.new(name, parse_stmt)
      end

      # @cur の識別子から括弧なし呼び出しが始まるか
      def command_call?
        return false unless @cur.type == IDENT
        return false if local?(@cur.literal)

        arg = peek
        case arg.type
        when LPAREN, LBRACKET
          # foo (1) / foo [1] は引数。foo(1) / foo[1] は違う
          arg.spaced
        when MINUS
          # foo -1 は引数。foo - 1 / foo-1 は引き算
          arg.spaced && !peek(2).spaced
        else
          COMMAND_ARG_START.include?(arg.type)
        end
      end

      def parse_command_call
        name = advance.literal
        args = [parse_expression(LOWEST)]
        while @cur.type == COMMA
          advance
          args << parse_expression(LOWEST)
        end
        AST::Call.new(name, args)
      end

      def parse_grouped
        advance # (
        expr = parse_stmt
        expect(RPAREN)
        expr
      end

      # 開始の括弧の次から読み、closing まで消費する
      def parse_list(closing)
        items = []
        unless @cur.type == closing
          items << parse_expression(LOWEST)
          while @cur.type == COMMA
            advance
            items << parse_expression(LOWEST)
          end
        end
        expect(closing)
        items
      end

      def parse_if
        advance # if
        cond = parse_stmt
        expect(NEWLINE)
        then_body = parse_body(BODY_END)

        elsifs = []
        while @cur.type == ELSIF
          advance
          elsif_cond = parse_stmt
          expect(NEWLINE)
          elsifs << [elsif_cond, parse_body(BODY_END)]
        end

        else_body = nil
        if @cur.type == ELSE
          advance
          else_body = parse_body(BODY_END)
        end

        expect(T_END)
        AST::If.new(cond, then_body, elsifs, else_body)
      end

      def parse_while
        advance # while
        cond = parse_stmt
        expect(NEWLINE)
        body = parse_body([T_END])
        expect(T_END)
        AST::While.new(cond, body)
      end

      def parse_def
        error("def cannot be nested in another def") if @scopes.size > 1
        advance # def
        name = expect(IDENT).literal

        params = []
        if @cur.type == LPAREN
          advance
          unless @cur.type == RPAREN
            params << expect(IDENT).literal
            while @cur.type == COMMA
              advance
              params << expect(IDENT).literal
            end
          end
          expect(RPAREN)
        end
        expect(NEWLINE)

        @scopes.push(Set.new(params))
        body = parse_body([T_END])
        @scopes.pop
        expect(T_END)
        AST::Def.new(name, params, body)
      end

      def parse_return
        advance # return
        if @cur.type == NEWLINE || @cur.type == EOF || BODY_END.include?(@cur.type)
          AST::Return.new(nil)
        else
          AST::Return.new(parse_stmt)
        end
      end
    end
  end
end
