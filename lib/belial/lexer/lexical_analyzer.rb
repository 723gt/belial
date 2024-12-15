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

    METHOD = "METHOD"
    T_END  = "END"
    LET      = "LET"

    KEYWORD = {
      "def" => METHOD,
      "end" => T_END,
      "let" => LET
    }
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
        skipWhiteSpace
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
        else
          if isLetter
            identifier = readIdentifier
            return Token.new(lookUPIdent(identifier), identifier)
          elsif isDigit
            return Token.new(INT, readNumber)
          else
            token = Token.new(ILLEGAL, @lexer.ch)
          end
        end
        readChar
        return token
      end

      private

      def readIdentifier
        pos = @lexer.position
        while isLetter
          readChar
        end
        @lexer.input[pos...@lexer.position]
      end

      def readNumber
        pos = @lexer.position
        while isDigit
          readChar
        end
        @lexer.input[pos...@lexer.position]
      end

      def isLetter
        /\A[a-zA-Z\_]\z/ === @lexer.ch
      end

      def isDigit
        /\A[0-9]\z/ === @lexer.ch
      end

      def lookUPIdent(identifier)
        if KEYWORD[identifier]
          return KEYWORD[identifier]
        else
          return IDENT
        end
      end

      def skipWhiteSpace
        while @lexer.ch == " " || @lexer.ch == "\t" || @lexer.ch == "\n" || @lexer.ch == "\r" do
          readChar
        end
      end
    end
  end
end
