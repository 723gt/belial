require 'minitest/autorun'
require './lib/belial/parser/parser.rb'
require './lib/belial/lexer/lexical_analyzer.rb'

class ParserTest < Minitest::Test
  def test_parser
    input = 'let x = 5;
             let y  = 10;
             let foobar = 83381;
            '

    tests = [
      'x',
      'y',
      'foobar'
    ]
    lexical_analyzer = Belial::Lexer::LexicalAnalyzer.new(input)
    parser = Belial::Parser::Parser.new(lexical_analyzer)
    program = parser.parse
    if program.nil?
      raise "program is nil"
    end

    if program.statements.size != 3
      raise "statement error dose not contain 3 statements, got #{program.statements.size}"
    end

    tests.each_with_index do |t, i|
      statement = program.statements[i]
      assert_equal(t_statement(statement, t), true)
    end
  end

  def test_error_parse
    input = 'let x 5
             let = 10
             let 83381
            '
    tests = [
      {"need_token"=> "=",  "error_literal" => "5"},
      {"need_token"=> "IDENT",  "error_literal" => "="},
      {"need_token"=> "IDENT",  "error_literal" => "83381"},
    ]
    lexical_analyzer = Belial::Lexer::LexicalAnalyzer.new(input)
    parser = Belial::Parser::Parser.new(lexical_analyzer)
    program = parser.parse
    errors = parser.errors

    if errors.size.zero?
      raise "errors is empty"
    end
    assert_equal(errors.size, 3)

    tests.each_with_index do |t, i|
      message = "expected next token to be #{t["need_token"]}, got #{t["error_literal"]} instead"
      assert_equal(errors[i], message)
    end

  end

  def t_statement(stm, val)
    if stm.token_literal != "let"
      raise "not statement let, got #{stm.token_literal}"
    end

    if stm.nil?
      raise "statement is nil"
    end

    if stm.name.value != val
      raise "statement name is not #{val}, got #{stm.name.value}"
    end

    if stm.name.token_literal != val
      raise "statement name is not #{val}, got #{stm.name.token_literal}"
    end
    return true
  end
end
