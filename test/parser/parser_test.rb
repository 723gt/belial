require 'minitest/autorun'
require_relative '../../lib/belial/parser/parser'

class ParserTest < Minitest::Test
  def test_literals
    assert_parse '1', '1'
    assert_parse '"a\"b"', '"a\"b"'
    assert_parse 'true', 'true'
    assert_parse 'false', 'false'
    assert_parse 'nil', 'nil'
    assert_parse '[1, "a", nil]', '(array 1 "a" nil)'
    assert_parse '[]', '(array)'
  end

  def test_operator_precedence
    assert_parse '1 + 2 * 3', '(+ 1 (* 2 3))'
    assert_parse '1 * 2 + 3', '(+ (* 1 2) 3)'
    assert_parse '1 - 2 - 3', '(- (- 1 2) 3)'
    assert_parse '(1 + 2) * 3', '(* (+ 1 2) 3)'
    assert_parse '-1 * 2', '(* (- 1) 2)'
    assert_parse '!true == false', '(== (! true) false)'
    assert_parse '1 < 2 == 3 > 4', '(== (< 1 2) (> 3 4))'
    assert_parse '1 <= 2 != 3 >= 4', '(!= (<= 1 2) (>= 3 4))'
    assert_parse '1 + 2 / 3 - 4', '(- (+ 1 (/ 2 3)) 4)'
    assert_parse '[1, 2][0] + 1', '(+ (index (array 1 2) 0) 1)'
  end

  def test_multiline_expression
    input = <<~SRC
      x = 1 +
        2
      foo(1,
        2)
    SRC
    expected = <<~SEXP.chomp
      (= x (+ 1 2))
      (call foo 1 2)
    SEXP
    assert_parse input, expected
  end

  def test_statement_separator
    assert_parse "a = 1; b = 2\n\n", "(= a 1)\n(= b 2)"
  end

  def test_assign_and_local_variable
    input = <<~SRC
      x = 1
      x + 2
      y = x = 3
    SRC
    expected = <<~SEXP.chomp
      (= x 1)
      (+ (lvar x) 2)
      (= y (= x 3))
    SEXP
    assert_parse input, expected
  end

  # 代入より前は呼び出し、後ろはローカル変数
  def test_identifier_before_and_after_assign
    input = <<~SRC
      puts x
      x = 1
      puts x
    SRC
    expected = <<~SEXP.chomp
      (call puts (call x))
      (= x 1)
      (call puts (lvar x))
    SEXP
    assert_parse input, expected
  end

  # docs/phase1.md の「識別子の解釈と括弧なし呼び出し」の表
  def test_call_forms
    assert_parse 'foo', '(call foo)'
    assert_parse 'foo()', '(call foo)'
    assert_parse 'foo(1, 2)', '(call foo 1 2)'
    assert_parse 'foo (1), 2', '(call foo 1 2)'
    assert_parse 'foo 1, 2', '(call foo 1 2)'
    assert_parse 'foo [1]', '(call foo (array 1))'
    assert_parse 'foo[1]', '(index (call foo) 1)'
    assert_parse 'foo -1', '(call foo (- 1))'
    assert_parse 'foo - 1', '(- (call foo) 1)'
    assert_parse 'foo-1', '(- (call foo) 1)'
    assert_parse 'foo !x', '(call foo (! (call x)))'
    assert_parse 'foo "a"', '(call foo "a")'
    assert_parse 'foo bar', '(call foo (call bar))'
  end

  def test_local_variable_is_never_command
    input = <<~SRC
      x = [1]
      x - 1
      x -1
      x [0]
      x[0]
    SRC
    expected = <<~SEXP.chomp
      (= x (array 1))
      (- (lvar x) 1)
      (- (lvar x) 1)
      (index (lvar x) 0)
      (index (lvar x) 0)
    SEXP
    assert_parse input, expected
  end

  def test_command_call_arguments
    assert_parse 'puts 1 + 2', '(call puts (+ 1 2))'
    assert_parse 'puts add(1, 2)', '(call puts (call add 1 2))'
    assert_parse 'puts (1 + 2) * 3', '(call puts (* (+ 1 2) 3))'
    assert_parse 'puts len(xs) == 3', '(call puts (== (call len (call xs)) 3))'
  end

  def test_command_call_positions
    assert_parse 'x = foo 1', '(= x (call foo 1))'
    assert_parse 'return foo 1', '(return (call foo 1))'
    assert_parse "if foo 1\n  2\nend", '(if (call foo 1) (body 2))'
    assert_parse "while foo 1\n  2\nend", '(while (call foo 1) (body 2))'
    assert_parse '(foo 1)', '(call foo 1)'
  end

  def test_command_call_not_allowed_inside_expression
    assert_parse_error '1 + foo 2'
    assert_parse_error 'puts len xs'
    assert_parse_error 'foo(bar 1)'
  end

  def test_if
    input = <<~SRC
      if a
        1
      elsif b
        2
      elsif c
        3
      else
        4
      end
    SRC
    expected = '(if (call a) (body 1) (elsif (call b) (body 2)) (elsif (call c) (body 3)) (else (body 4)))'
    assert_parse input, expected

    assert_parse "if a\nend", '(if (call a) (body))'
    assert_parse "x = if a\n  1\nelse\n  2\nend", '(= x (if (call a) (body 1) (else (body 2))))'
  end

  def test_while
    input = <<~SRC
      i = 0
      while i < 10
        i = i + 1
      end
    SRC
    expected = <<~SEXP.chomp
      (= i 0)
      (while (< (lvar i) 10) (body (= i (+ (lvar i) 1))))
    SEXP
    assert_parse input, expected
  end

  def test_def
    input = <<~SRC
      def add(x, y)
        return x + y
      end
      add(1, 2)
    SRC
    expected = <<~SEXP.chomp
      (def add (params x y) (body (return (+ (lvar x) (lvar y)))))
      (call add 1 2)
    SEXP
    assert_parse input, expected
  end

  def test_def_without_params
    input = <<~SRC
      def hello
        puts "hi"
        return
      end
      hello
    SRC
    expected = <<~SEXP.chomp
      (def hello (params) (body (call puts "hi") (return)))
      (call hello)
    SEXP
    assert_parse input, expected
  end

  # メソッドからトップレベルの変数は見えない
  def test_def_has_own_scope
    input = <<~SRC
      x = 1
      def foo(y)
        x + y
      end
      x
    SRC
    expected = <<~SEXP.chomp
      (= x 1)
      (def foo (params y) (body (+ (call x) (lvar y))))
      (lvar x)
    SEXP
    assert_parse input, expected
  end

  # docs/phase1.md の到達目標のサンプル
  def test_phase1_sample
    input = <<~SRC
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
    SRC
    expected = <<~SEXP.chomp
      (def fib (params n) (body (if (< (lvar n) 2) (body (return (lvar n)))) (+ (call fib (- (lvar n) 1)) (call fib (- (lvar n) 2)))))
      (= i 0)
      (while (< (lvar i) 10) (body (call puts (call fib (lvar i))) (= i (+ (lvar i) 1))))
      (= xs (array 1 2 3))
      (call puts (call len (lvar xs)))
      (call puts (== (index (lvar xs) 0) 1))
      (def hello (params) (body (call puts "hello")))
      (call hello)
    SEXP
    assert_parse input, expected
  end

  def test_errors
    assert_parse_error 'def a', /\A1:6: expected NEWLINE, got end of input/
    assert_parse_error "def a\n  def b\n  end\nend", /\A2:3: def cannot be nested/
    assert_parse_error '(1 + 2', /\A1:7: expected \), got end of input/
    assert_parse_error "if x == 1 2\nend", /\A1:11: expected NEWLINE, got '2'/
    assert_parse_error 'end', /\A1:1: unexpected 'end'/
    assert_parse_error '1 2', /\A1:3: unexpected '2'/
    assert_parse_error '"abc', /\A1:1: unexpected '"abc'/
  end

  private

  def parse(input)
    Belial::Parser::Parser.new(input).parse_program
  end

  def assert_parse(input, expected)
    assert_equal expected, parse(input).to_sexp, "input: #{input.inspect}"
  end

  def assert_parse_error(input, message = nil)
    error = assert_raises(Belial::Parser::ParseError, "input: #{input.inspect}") { parse(input) }
    assert_match message, error.message if message
  end
end
