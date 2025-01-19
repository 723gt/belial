require 'minitest/autorun'
require './lib/belial/parser/parser.rb'
require './lib/belial/lexer/lexical_analyzer.rb'

class PrefixExpressionTest < Minitest::Test
  def test_prefix_expression
    input = '!5; -15;'

    lexical_analyzer = Belial::Lexer::LexicalAnalyzer.new(input)
    parser = Belial::Parser::Parser.new(lexical_analyzer)
    program = parser.parse

    assert_equal(program.statements.size, 2)

    tests = [
      { "expected_operator" => "!", "expected_value" => 5 },
      { "expected_operator" => "-", "expected_value" => 15 }
    ]

    tests.each_with_index do |t, i|
      statement = program.statements[i]
      expression = statement.expression
      if expression.nil?
        raise "expression is nil"
      end
      assert_equal(expression.operator, t["expected_operator"])
      t_integer_literal(expression.right, t["expected_value"])
    end
  end

  def t_integer_literal(expression, value)
    if expression.nil?
      raise "expression is nil"
    end
    assert_equal(expression.value, value)
    assert_equal(expression.token_literal, value.to_s)
  end
end
