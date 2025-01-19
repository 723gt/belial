require 'minitest/autorun'
require './lib/belial/parser/parser.rb'
require './lib/belial/lexer/lexical_analyzer.rb'

class IdentifierExpressionTest < Minitest::Test
  def test_identifier_expression
    input = 'foobar;'

    lexical_analyzer = Belial::Lexer::LexicalAnalyzer.new(input)
    parser = Belial::Parser::Parser.new(lexical_analyzer)
    program = parser.parse

    assert_equal(program.statements.size, 1)
    statement = program.statements[0]
    if statement.nil?
      raise "statement is nil"
    end
    ident = statement.expression
    assert_equal(ident.token_literal, "foobar")
    assert_equal(ident.value, "foobar")
  end
end
