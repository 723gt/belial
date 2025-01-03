require 'minitest/autorun'
require './lib/belial/parser/parser.rb'
require './lib/belial/lexer/lexical_analyzer.rb'

class InfixExpressionTest < Minitest::Test
  def test_infix_expression
    input = [["5 + 5", 5, "+", 5],
             ["5 - 5", 5, "-", 5],
             ["5 * 5", 5, "*", 5],
             ["5 / 5", 5, "/", 5],
             ["5 < 5", 5, "<", 5],
             ["5 > 5", 5, ">", 5],
             ["5 == 5", 5, "==", 5],
             ["5 != 5", 5, "!=", 5]]
    input.each do |i|
      lexical_analyzer = Belial::Lexer::LexicalAnalyzer.new(i[0])
      parser = Belial::Parser::Parser.new(lexical_analyzer)
      program = parser.parse
      assert_equal(program.statements.size, 1)
      statement = program.statements[0]
      expression = statement.expression
      if expression.nil?
        raise "expression is nil"
      end
      t_integer_literal(expression.left, i[1])
      assert_equal(expression.operator, i[2])
      t_integer_literal(expression.right, i[3])
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
