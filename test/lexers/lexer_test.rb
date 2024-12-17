require 'minitest/autorun'
require './lib/belial/lexer/lexical_analyzer.rb'
require './lib/belial/lexer/token.rb'

class LexicalAnalyzerTest < Minitest::Test

  def test_variable
    input = 'let five = 5
            let ten = 10
            let result = add(five, ten)
            '

    tests = [
      Belial::Lexer::Token.new(Belial::Lexer::LET, "let"),
      Belial::Lexer::Token.new(Belial::Lexer::IDENT, "five"),
      Belial::Lexer::Token.new(Belial::Lexer::ASSIGN, Belial::Lexer::ASSIGN),
      Belial::Lexer::Token.new(Belial::Lexer::INT, 5),

      Belial::Lexer::Token.new(Belial::Lexer::LET, "let"),
      Belial::Lexer::Token.new(Belial::Lexer::IDENT, "ten"),
      Belial::Lexer::Token.new(Belial::Lexer::ASSIGN, Belial::Lexer::ASSIGN),
      Belial::Lexer::Token.new(Belial::Lexer::INT, 10),

      Belial::Lexer::Token.new(Belial::Lexer::LET, "let"),
      Belial::Lexer::Token.new(Belial::Lexer::IDENT, "result"),
      Belial::Lexer::Token.new(Belial::Lexer::ASSIGN, Belial::Lexer::ASSIGN),

      Belial::Lexer::Token.new(Belial::Lexer::IDENT, "add"),
      Belial::Lexer::Token.new(Belial::Lexer::LPAREN, Belial::Lexer::LPAREN),
      Belial::Lexer::Token.new(Belial::Lexer::IDENT, "five"),
      Belial::Lexer::Token.new(Belial::Lexer::COMMA, Belial::Lexer::COMMA),
      Belial::Lexer::Token.new(Belial::Lexer::IDENT, "ten"),
      Belial::Lexer::Token.new(Belial::Lexer::RPAREN, Belial::Lexer::RPAREN),
      Belial::Lexer::Token.new(Belial::Lexer::EOF, "0"),
    ]
    execute_test(input, tests)
  end

  def test_formula
    input = '
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
            '
    tests = [
      Belial::Lexer::Token.new(Belial::Lexer::INT, 1),
      Belial::Lexer::Token.new(Belial::Lexer::LT, "<"),
      Belial::Lexer::Token.new(Belial::Lexer::INT, 2),

      Belial::Lexer::Token.new(Belial::Lexer::INT, 2),
      Belial::Lexer::Token.new(Belial::Lexer::GT, ">"),
      Belial::Lexer::Token.new(Belial::Lexer::INT, 3),

      Belial::Lexer::Token.new(Belial::Lexer::IDENT, "c"),
      Belial::Lexer::Token.new(Belial::Lexer::MINUS, Belial::Lexer::MINUS),
      Belial::Lexer::Token.new(Belial::Lexer::IDENT, "d"),

      Belial::Lexer::Token.new(Belial::Lexer::IDENT, "a"),
      Belial::Lexer::Token.new(Belial::Lexer::ASTERISK, Belial::Lexer::ASTERISK),
      Belial::Lexer::Token.new(Belial::Lexer::IDENT, "b"),

      Belial::Lexer::Token.new(Belial::Lexer::IDENT, "c"),
      Belial::Lexer::Token.new(Belial::Lexer::SLASH, Belial::Lexer::SLASH),
      Belial::Lexer::Token.new(Belial::Lexer::IDENT, "d"),

      Belial::Lexer::Token.new(Belial::Lexer::INT, 1),
      Belial::Lexer::Token.new(Belial::Lexer::EQ, "=="),
      Belial::Lexer::Token.new(Belial::Lexer::INT, 1),

      Belial::Lexer::Token.new(Belial::Lexer::INT, 1),
      Belial::Lexer::Token.new(Belial::Lexer::NOT_EQ, "!="),
      Belial::Lexer::Token.new(Belial::Lexer::INT, 2),

      Belial::Lexer::Token.new(Belial::Lexer::BANG, Belial::Lexer::BANG),
      Belial::Lexer::Token.new(Belial::Lexer::IDENT, "x"),

      Belial::Lexer::Token.new(Belial::Lexer::INT, 1),
      Belial::Lexer::Token.new(Belial::Lexer::LTQ, "<="),
      Belial::Lexer::Token.new(Belial::Lexer::INT, 2),

      Belial::Lexer::Token.new(Belial::Lexer::INT, 2),
      Belial::Lexer::Token.new(Belial::Lexer::GTQ, ">="),
      Belial::Lexer::Token.new(Belial::Lexer::INT, 3),



      Belial::Lexer::Token.new(Belial::Lexer::EOF, "0")
    ]

    execute_test(input, tests)
  end

  def test_method
    input = 'def add(x, y)
              return x + y
             end
            '

    tests = [
      Belial::Lexer::Token.new(Belial::Lexer::METHOD, "def"),
      Belial::Lexer::Token.new(Belial::Lexer::IDENT, "add"),
      Belial::Lexer::Token.new(Belial::Lexer::LPAREN, Belial::Lexer::LPAREN),
      Belial::Lexer::Token.new(Belial::Lexer::IDENT, "x"),
      Belial::Lexer::Token.new(Belial::Lexer::COMMA, Belial::Lexer::COMMA),
      Belial::Lexer::Token.new(Belial::Lexer::IDENT, "y"),
      Belial::Lexer::Token.new(Belial::Lexer::RPAREN, Belial::Lexer::RPAREN),

      Belial::Lexer::Token.new(Belial::Lexer::RETURN, "return"),
      Belial::Lexer::Token.new(Belial::Lexer::IDENT, "x"),
      Belial::Lexer::Token.new(Belial::Lexer::PLUS, Belial::Lexer::PLUS),
      Belial::Lexer::Token.new(Belial::Lexer::IDENT, "y"),

      Belial::Lexer::Token.new(Belial::Lexer::T_END, "end"),

      Belial::Lexer::Token.new(Belial::Lexer::EOF, "0")
    ]
    execute_test(input, tests)
  end

  def test_if
    input = '
            if a > 1
              true
            else
              false
            end
            '
    tests = [
      Belial::Lexer::Token.new(Belial::Lexer::IF, "if"),
      Belial::Lexer::Token.new(Belial::Lexer::IDENT, "a"),
      Belial::Lexer::Token.new(Belial::Lexer::GT, ">"),
      Belial::Lexer::Token.new(Belial::Lexer::INT, 1),
      Belial::Lexer::Token.new(Belial::Lexer::TRUE, "true"),

      Belial::Lexer::Token.new(Belial::Lexer::ELSE, "else"),
      Belial::Lexer::Token.new(Belial::Lexer::FALSE, "false"),
      Belial::Lexer::Token.new(Belial::Lexer::T_END, "end"),

      Belial::Lexer::Token.new(Belial::Lexer::EOF, "0")
    ]
    execute_test(input, tests)
  end

  def execute_test(input, tests)
    lexical_analyzer = Belial::Lexer::LexicalAnalyzer.new(input)
    lexer = lexical_analyzer.createLexer
    tests.each do |test|
      t = lexical_analyzer.nextToken
      assert_equal t.type, test.type
      assert_equal t.literal, test.literal
    end
  end
end
