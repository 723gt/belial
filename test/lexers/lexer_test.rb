require 'minitest/autorun'
require_relative '../../lib/belial/lexer/lexical_analyzer'

class LexicalAnalyzerTest < Minitest::Test
  include Belial::Lexer

  def test_variable
    input = <<~SRC
      five = 5
      ten = 10
      result = add(five, ten)
    SRC

    tests = [
      [IDENT, "five"], [ASSIGN, "="], [INT, "5"], [NEWLINE, "\n"],
      [IDENT, "ten"], [ASSIGN, "="], [INT, "10"], [NEWLINE, "\n"],
      [IDENT, "result"], [ASSIGN, "="],
      [IDENT, "add"], [LPAREN, "("], [IDENT, "five"], [COMMA, ","], [IDENT, "ten"], [RPAREN, ")"],
      [NEWLINE, "\n"],
      [EOF, ""]
    ]
    execute_test(input, tests)
  end

  def test_formula
    input = <<~SRC
      1 < 2
      2 > 3
      c - d
      a * b
      c / d
      1 == 1
      1 != 2
      !x
      1 <= 2
      2 >= 3
    SRC

    tests = [
      [INT, "1"], [LT, "<"], [INT, "2"], [NEWLINE, "\n"],
      [INT, "2"], [GT, ">"], [INT, "3"], [NEWLINE, "\n"],
      [IDENT, "c"], [MINUS, "-"], [IDENT, "d"], [NEWLINE, "\n"],
      [IDENT, "a"], [ASTERISK, "*"], [IDENT, "b"], [NEWLINE, "\n"],
      [IDENT, "c"], [SLASH, "/"], [IDENT, "d"], [NEWLINE, "\n"],
      [INT, "1"], [EQ, "=="], [INT, "1"], [NEWLINE, "\n"],
      [INT, "1"], [NOT_EQ, "!="], [INT, "2"], [NEWLINE, "\n"],
      [BANG, "!"], [IDENT, "x"], [NEWLINE, "\n"],
      [INT, "1"], [LTQ, "<="], [INT, "2"], [NEWLINE, "\n"],
      [INT, "2"], [GTQ, ">="], [INT, "3"], [NEWLINE, "\n"],
      [EOF, ""]
    ]
    execute_test(input, tests)
  end

  def test_method
    input = <<~SRC
      def add(x, y)
        return x + y
      end
    SRC

    tests = [
      [METHOD, "def"], [IDENT, "add"],
      [LPAREN, "("], [IDENT, "x"], [COMMA, ","], [IDENT, "y"], [RPAREN, ")"], [NEWLINE, "\n"],
      [RETURN, "return"], [IDENT, "x"], [PLUS, "+"], [IDENT, "y"], [NEWLINE, "\n"],
      [T_END, "end"], [NEWLINE, "\n"],
      [EOF, ""]
    ]
    execute_test(input, tests)
  end

  def test_if
    input = <<~SRC
      if a > 1
        true
      elsif a == 0
        nil
      else
        false
      end
    SRC

    tests = [
      [IF, "if"], [IDENT, "a"], [GT, ">"], [INT, "1"], [NEWLINE, "\n"],
      [TRUE, "true"], [NEWLINE, "\n"],
      [ELSIF, "elsif"], [IDENT, "a"], [EQ, "=="], [INT, "0"], [NEWLINE, "\n"],
      [NIL, "nil"], [NEWLINE, "\n"],
      [ELSE, "else"], [NEWLINE, "\n"],
      [FALSE, "false"], [NEWLINE, "\n"],
      [T_END, "end"], [NEWLINE, "\n"],
      [EOF, ""]
    ]
    execute_test(input, tests)
  end

  def test_while
    input = <<~SRC
      while i < 10
        i = i + 1
      end
    SRC

    tests = [
      [WHILE, "while"], [IDENT, "i"], [LT, "<"], [INT, "10"], [NEWLINE, "\n"],
      [IDENT, "i"], [ASSIGN, "="], [IDENT, "i"], [PLUS, "+"], [INT, "1"], [NEWLINE, "\n"],
      [T_END, "end"], [NEWLINE, "\n"],
      [EOF, ""]
    ]
    execute_test(input, tests)
  end

  def test_let_is_identifier
    execute_test("let", [[IDENT, "let"], [EOF, ""]])
  end

  def test_identifier_with_digit
    execute_test("x1 = _a2", [[IDENT, "x1"], [ASSIGN, "="], [IDENT, "_a2"], [EOF, ""]])
  end

  def test_string
    input = <<~'SRC'
      "hello" "a\"b\\c\n\td" ""
    SRC

    tests = [
      [STRING, "hello"], [STRING, "a\"b\\c\n\td"], [STRING, ""], [NEWLINE, "\n"],
      [EOF, ""]
    ]
    execute_test(input, tests)
  end

  def test_unterminated_string
    execute_test('"abc', [[ILLEGAL, '"abc'], [EOF, ""]])
  end

  def test_array
    input = <<~SRC
      xs = [1, 2]
      xs[0]
    SRC

    tests = [
      [IDENT, "xs"], [ASSIGN, "="],
      [LBRACKET, "["], [INT, "1"], [COMMA, ","], [INT, "2"], [RBRACKET, "]"], [NEWLINE, "\n"],
      [IDENT, "xs"], [LBRACKET, "["], [INT, "0"], [RBRACKET, "]"], [NEWLINE, "\n"],
      [EOF, ""]
    ]
    execute_test(input, tests)
  end

  def test_comment
    input = <<~SRC
      x = 1 # 行末のコメント
      # 行全体のコメント
      y
    SRC

    tests = [
      [IDENT, "x"], [ASSIGN, "="], [INT, "1"], [NEWLINE, "\n"],
      [IDENT, "y"], [NEWLINE, "\n"],
      [EOF, ""]
    ]
    execute_test(input, tests)
  end

  def test_newlines_are_collapsed
    input = "\n\na\n\n\nb;c;\n"

    tests = [
      [IDENT, "a"], [NEWLINE, "\n"],
      [IDENT, "b"], [NEWLINE, ";"],
      [IDENT, "c"], [NEWLINE, ";"],
      [EOF, ""]
    ]
    execute_test(input, tests)
  end

  def test_line_continuation
    input = <<~SRC
      x = 1 +
        2
      foo(1,
        2
      )
      xs = [
        1
      ]
    SRC

    tests = [
      [IDENT, "x"], [ASSIGN, "="], [INT, "1"], [PLUS, "+"], [INT, "2"], [NEWLINE, "\n"],
      [IDENT, "foo"], [LPAREN, "("], [INT, "1"], [COMMA, ","], [INT, "2"], [RPAREN, ")"], [NEWLINE, "\n"],
      [IDENT, "xs"], [ASSIGN, "="], [LBRACKET, "["], [INT, "1"], [RBRACKET, "]"], [NEWLINE, "\n"],
      [EOF, ""]
    ]
    execute_test(input, tests)
  end

  def test_spaced
    # 括弧なし呼び出しの判定に使う「直前に空白があったか」
    input = "foo(1) foo (1) foo[1] foo [1] foo -1 foo - 1"
    actual = tokenize(input).map { |t| [t.literal, t.spaced] }

    expected = [
      ["foo", true], ["(", false], ["1", false], [")", false],
      ["foo", true], ["(", true], ["1", false], [")", false],
      ["foo", true], ["[", false], ["1", false], ["]", false],
      ["foo", true], ["[", true], ["1", false], ["]", false],
      ["foo", true], ["-", true], ["1", false],
      ["foo", true], ["-", true], ["1", true],
      ["", false]
    ]
    assert_equal expected, actual
  end

  def test_position
    input = "a = 1\n  bc >= 2"
    actual = tokenize(input).map { |t| [t.literal, t.line, t.column] }

    expected = [
      ["a", 1, 1], ["=", 1, 3], ["1", 1, 5], ["\n", 1, 6],
      ["bc", 2, 3], [">=", 2, 6], ["2", 2, 9],
      ["", 2, 10]
    ]
    assert_equal expected, actual
  end

  private

  def execute_test(input, tests)
    actual = tokenize(input).map { |t| [t.type, t.literal] }
    assert_equal tests, actual
  end

  # EOF まで読んだトークンの配列を返す
  def tokenize(input)
    lexical_analyzer = LexicalAnalyzer.new(input)
    lexical_analyzer.createLexer
    tokens = []
    loop do
      token = lexical_analyzer.nextToken
      tokens << token
      break if token.type == EOF
    end
    tokens
  end
end
