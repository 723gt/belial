require 'minitest/autorun'
require './lib/belial/parser/parser.rb'
require './lib/belial/lexer/lexical_analyzer.rb'

class BooleanExpressionTest < Minitest::Test
  def test_boolean_expression_true
    input = 'true;'

    lexical_analyzer = Belial::Lexer::LexicalAnalyzer.new(input)
    parser = Belial::Parser::Parser.new(lexical_analyzer)
    program = parser.parse

    assert_equal(program.statements.size, 1)
    statement = program.statements[0]
    if statement.nil?
      raise "statement is nil"
    end
    ident = statement.expression
    assert_equal(ident.token_literal, "true")
    assert_equal(ident.value, true)
  end

  def test_boolean_expression_false
    input = 'false;'

    lexical_analyzer = Belial::Lexer::LexicalAnalyzer.new(input)
    parser = Belial::Parser::Parser.new(lexical_analyzer)
    program = parser.parse

    assert_equal(program.statements.size, 1)
    statement = program.statements[0]
    if statement.nil?
      raise "statement is nil"
    end
    ident = statement.expression
    assert_equal(ident.token_literal, "false")
    assert_equal(ident.value, false)
  end
end
