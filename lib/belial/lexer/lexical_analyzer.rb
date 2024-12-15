require './lib/belial/lexer/lexer.rb'
require './lib/belial/lexer/token.rb'
module Belial
  module Lexer
    ILLEGAL = "ILLEGAL"
    EOF     = "EOF"

    IDENT   = "IDENT"
    INT     = "INT"

    ASSIGN  = "="
    PLUS    = "+"

    COMMA   = ","
    SEMICOLON = ";"

    LPAREN = "("
    RPAREN = ")"
    LBRACE = "{"
    RBRACE = "}"

    FUNCTION = "FUNCTION"
    LET      = "LET"
    class LexicalAnalyzer
      def initialize(input)
        @input = input
      end

      def createLexer
        @lexer = Lexer.new(@input)
        readChar
        return @lexer
      end

      def readChar()
        if @lexer.read_position >= @lexer.input.length
          @lexer.ch = 0
        else
          @lexer.ch = @lexer.input[@lexer.read_position]
        end
        @lexer.position = @lexer.read_position
        @lexer.read_position += 1
      end

      def nextToken
        puts "nextToken: #{@lexer.ch}"
        case @lexer.ch
        when ASSIGN
          token = Token.new(ASSIGN, @lexer.ch)
        when SEMICOLON
          token = Token.new(SEMICOLON, @lexer.ch)
        when LPAREN
          token = Token.new(LPAREN, @lexer.ch)
        when RPAREN
          token = Token.new(RPAREN, @lexer.ch)
        when COMMA
          token = Token.new(COMMA, @lexer.ch)
        when PLUS
          token = Token.new(PLUS, @lexer.ch)
        when LBRACE
          token = Token.new(LBRACE, @lexer.ch)
        when RBRACE
          token = Token.new(RBRACE, @lexer.ch)
        when 0
          token = Token.new(EOF, @lexer.ch)
        end
        readChar
        return token
      end
    end
  end
end
