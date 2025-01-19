require 'minitest/autorun'
require './lib/belial/parser/parser.rb'
require './lib/belial/lexer/lexical_analyzer.rb'

class IntegerLiteralExpressionTest < Minitest::Test
  def test_integer_literal_expression
    input = '5;'
    lexical_analyzer = Belial::Lexer::LexicalAnalyzer.new(input)
    parser = Belial::Parser::Parser.new(lexical_analyzer)
    program = parser.parse
    assert_equal(program.statements.size, 1)

    statement = program.statements[0]
    literal = statement.expression
    puts "literal: #{literal}"
    assert_equal(literal.token_literal, '5')
    assert_equal(literal.value, 5)
  end
end
