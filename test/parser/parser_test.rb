require 'minitest/autorun'
require './lib/belial/parser/parser.rb'
require './lib/belial/lexer/lexical_analyzer.rb'

class ParserTest < Minitest::Test
  def test_parser
    input = 'let five = 5;
             let ten = 10;
             let foobar = 83381;
            '

    tests = [
      {"identifier" => "x"},
      {"identifier" => "y"},
      {"identifier" => "foobar"},
    ]
    lexical_analyzer = Belial::Lexer::LexicalAnalyzer.new(input)
    parser = Belial::Parser::Parser.new(lexical_analyzer)
    program = parser.parser_program
    if program.nil?
      raise "program is nil"
    end

    if program.statements.size != 3
      raise "statement error dose not contain 3 statements, got #{program.statements.size}"
    end

    tests.each_with_index do |test, i|
      statement = program.statements[i]
      assert_true(test_statement(test, statement, test))
    end
  end

  def test_statement(test, statement, value)
    if statement.token_literal != "let"
      raise "not statement let, got #{statement.token_literal}"
    end

    if statement.nil?
      raise "statement is nil"
    end

    if statement.name.value != value
      raise "statement name is not #{value}, got #{statement.name.value}"
    end

    if statement.name.token_literal != value
      raise "statement name is not #{value}, got #{statement.name.token_literal}"
    end
    return true
  end
end
