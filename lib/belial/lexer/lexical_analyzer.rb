require_relative 'lexer'
require_relative 'token'
module Belial
  module Lexer
    ILLEGAL = "ILLEGAL"
    EOF     = "EOF"
    NEWLINE = "NEWLINE"

    IDENT   = "IDENT"
    INT     = "INT"
    STRING  = "STRING"

    ASSIGN  = "="
    PLUS    = "+"
    MINUS   = "-"
    BANG    = "!"
    ASTERISK = "*"
    SLASH   = "/"

    EQ = "=="
    NOT_EQ = "!="

    LT = "<"
    GT = ">"

    LTQ = "<="
    GTQ = ">="

    COMMA   = ","
    SEMICOLON = ";"

    LPAREN = "("
    RPAREN = ")"
    LBRACE = "{"
    RBRACE = "}"
    LBRACKET = "["
    RBRACKET = "]"

    METHOD = "METHOD"
    T_END  = "END"
    TRUE   = "TRUE"
    FALSE  = "FALSE"
    NIL    = "NIL"
    IF     = "IF"
    ELSIF  = "ELSIF"
    ELSE   = "ELSE"
    WHILE  = "WHILE"
    RETURN = "RETURN"

    KEYWORD = {
      "def" => METHOD,
      "end" => T_END,
      "if" => IF,
      "elsif" => ELSIF,
      "else" => ELSE,
      "while" => WHILE,
      "true" => TRUE,
      "false" => FALSE,
      "nil" => NIL,
      "return" => RETURN
    }

    # この種類のトークンの直後の改行は文の区切りにしない（式を複数行に分けて書けるように）
    CONTINUE_LINE = [
      NEWLINE, COMMA, ASSIGN, PLUS, MINUS, ASTERISK, SLASH, BANG,
      EQ, NOT_EQ, LT, GT, LTQ, GTQ, LPAREN, LBRACKET
    ]

    ESCAPES = {
      "n" => "\n",
      "t" => "\t",
      '"' => '"',
      "\\" => "\\"
    }

    class LexicalAnalyzer
      def initialize(input)
        @input = input
      end

      def createLexer
        @lexer = Lexer.new(@input)
        @last_token = nil
        @nest = 0 # ( と [ の深さ。括弧の中の改行は文の区切りにしない
        readChar
        return @lexer
      end

      def readChar
        if @lexer.ch == "\n"
          @lexer.line += 1
          @lexer.column = 1
        else
          @lexer.column += 1
        end
        if @lexer.read_position >= @lexer.input.length
          @lexer.ch = nil
        else
          @lexer.ch = @lexer.input[@lexer.read_position]
        end
        @lexer.position = @lexer.read_position
        @lexer.read_position += 1
      end

      def peekChar
        if @lexer.read_position >= @lexer.input.length
          return nil
        else
          return @lexer.input[@lexer.read_position]
        end
      end

      def nextToken
        @spaced = skipWhiteSpace
        @start_line = @lexer.line
        @start_column = @lexer.column
        token = readToken
        case token.type
        when LPAREN, LBRACKET
          @nest += 1
        when RPAREN, RBRACKET
          @nest -= 1 if @nest > 0
        end
        @last_token = token
      end

      private

      def readToken
        case @lexer.ch
        when "\n", SEMICOLON
          token = newToken(NEWLINE, @lexer.ch)
        when ASSIGN
          if peekChar == "="
            readChar
            token = newToken(EQ, EQ)
          else
            token = newToken(ASSIGN, @lexer.ch)
          end
        when LPAREN
          token = newToken(LPAREN, @lexer.ch)
        when RPAREN
          token = newToken(RPAREN, @lexer.ch)
        when LBRACKET
          token = newToken(LBRACKET, @lexer.ch)
        when RBRACKET
          token = newToken(RBRACKET, @lexer.ch)
        when COMMA
          token = newToken(COMMA, @lexer.ch)
        when PLUS
          token = newToken(PLUS, @lexer.ch)
        when MINUS
          token = newToken(MINUS, @lexer.ch)
        when BANG
          if peekChar == "="
            readChar
            token = newToken(NOT_EQ, NOT_EQ)
          else
            token = newToken(BANG, @lexer.ch)
          end
        when ASTERISK
          token = newToken(ASTERISK, @lexer.ch)
        when SLASH
          token = newToken(SLASH, @lexer.ch)
        when LT
          if peekChar == '='
            readChar
            token = newToken(LTQ, LTQ)
          else
            token = newToken(LT, @lexer.ch)
          end
        when GT
          if peekChar == '='
            readChar
            token = newToken(GTQ, GTQ)
          else
            token = newToken(GT, @lexer.ch)
          end
        when LBRACE
          token = newToken(LBRACE, @lexer.ch)
        when RBRACE
          token = newToken(RBRACE, @lexer.ch)
        when '"'
          return readString
        when nil
          return newToken(EOF, "")
        else
          if isLetter
            identifier = readIdentifier
            return newToken(lookUPIdent(identifier), identifier)
          elsif isDigit
            return newToken(INT, readNumber)
          else
            token = newToken(ILLEGAL, @lexer.ch)
          end
        end
        readChar
        return token
      end

      def newToken(type, literal)
        Token.new(type, literal, line: @start_line, column: @start_column, spaced: @spaced)
      end

      def readIdentifier
        pos = @lexer.position
        while isLetter || isDigit
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

      # 開始の " の位置で呼ばれ、終了の " の次まで読み進める
      def readString
        readChar
        str = +""
        until @lexer.ch == '"'
          # 閉じていない文字列
          return newToken(ILLEGAL, '"' + str) if @lexer.ch.nil?
          if @lexer.ch == "\\"
            readChar
            return newToken(ILLEGAL, '"' + str) if @lexer.ch.nil?
            str << ESCAPES.fetch(@lexer.ch, @lexer.ch)
          else
            str << @lexer.ch
          end
          readChar
        end
        readChar
        newToken(STRING, str)
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

      # 空白・コメント・文の区切りにならない改行を読み飛ばす。
      # 何か読み飛ばしたか（入力の先頭も含む）を返す
      def skipWhiteSpace
        skipped = @last_token.nil?
        loop do
          case @lexer.ch
          when " ", "\t", "\r"
            readChar
          when "#"
            readChar until @lexer.ch.nil? || @lexer.ch == "\n"
          when "\n", SEMICOLON
            break unless continueLine?
            readChar
          else
            break
          end
          skipped = true
        end
        skipped
      end

      def continueLine?
        @nest > 0 || @last_token.nil? || CONTINUE_LINE.include?(@last_token.type)
      end
    end
  end
end
