require 'minitest/autorun'
require './lib/belial/lexer/lexical_analyzer.rb'
require './lib/belial/lexer/token.rb'

class LexicalAnalyzerTest < Minitest::Test

  def test_createLexer
    input = '=+(){},;'
    tests = [
      Belial::Lexer::Token.new(Belial::Lexer::ASSIGN, Belial::Lexer::ASSIGN),
      Belial::Lexer::Token.new(Belial::Lexer::PLUS, Belial::Lexer::PLUS),
      Belial::Lexer::Token.new(Belial::Lexer::LPAREN, Belial::Lexer::LPAREN),
      Belial::Lexer::Token.new(Belial::Lexer::RPAREN, Belial::Lexer::RPAREN),
      Belial::Lexer::Token.new(Belial::Lexer::LBRACE, Belial::Lexer::LBRACE),
      Belial::Lexer::Token.new(Belial::Lexer::RBRACE, Belial::Lexer::RBRACE),
      Belial::Lexer::Token.new(Belial::Lexer::COMMA, Belial::Lexer::COMMA),
      Belial::Lexer::Token.new(Belial::Lexer::SEMICOLON, Belial::Lexer::SEMICOLON)
    ]
    lexical_analyzer = Belial::Lexer::LexicalAnalyzer.new(input)
    lexer = lexical_analyzer.createLexer
    tests.each do |test|
      puts "token: #{test.type}, #{test.literal}"
      t = lexical_analyzer.nextToken
      assert_equal t.type, test.type
      assert_equal t.literal, test.literal
    end
  end
end
