require './lib/belial/parser/ats/program'
require './lib/belial/parser/ats/let_statement'
require './lib/belial/parser/ats/return_statement'
require './lib/belial/parser/ats/expression_statement'
require './lib/belial/parser/ats/prefix_expression'
require './lib/belial/parser/ats/infix_expression'

require './lib/belial/parser/ats/asserts/identifier'
require './lib/belial/parser/ats/asserts/integer_literal'

require './lib/belial/lexer/token'
require './lib/belial/lexer/lexical_analyzer.rb'

module Belial
  module Parser
    LOWEST = 1
    EQUALS = 2  # ==
    LESSGREATER = 3 # > or <
    SUM = 4 # +
    PRODUCT = 5 # *
    PREFIX = 6 # -X or !X
    CALL = 7 # myFunction(X)

    IDENTIFIER_EXPRESSION = :parse_identifier
    INTEGER_EXPRESSION = :parse_integer_literal
    PREFIX_EXPRESSION = :parse_prefix_expression
    INFIX_EXPRESSION = :parse_infix_expression

    PRECEDENCES = {
      Belial::Lexer::EQ => EQUALS,
      Belial::Lexer::NOT_EQ => EQUALS,
      Belial::Lexer::LT => LESSGREATER,
      Belial::Lexer::GT => LESSGREATER,
      Belial::Lexer::PLUS => SUM,
      Belial::Lexer::MINUS => SUM,
      Belial::Lexer::ASTERISK => PRODUCT,
      Belial::Lexer::SLASH => PRODUCT,
    }

    class Parser
      attr_reader :errors
      def initialize(lexical_analyzer)
        @program = Belial::Parser::ATS::Program.new
        @lexer = lexical_analyzer
        @current_token = nil
        @peek_token = nil
        @errors = []
        @prefix_parse_fnc = {}
        @infix_parse_fnc = {}

        init_prefix
        init_infix

        next_token
        next_token
      end

      def next_token
        @current_token = @peek_token
        @peek_token = @lexer.next_token
      end

      def parse
        while !is_a_current_token?(Belial::Lexer::EOF)
          stm = parse_statement
          if !stm.nil?
            @program.add_statement(stm)
          end
          next_token
        end
        return @program
      end

      def parse_statement
        case @current_token.type
        when Belial::Lexer::LET
          return parse_let_statement
        when Belial::Lexer::RETURN
          return parse_return_statement
        else
          return parse_expression_statement
        end
      end

      private
      # letのパース
      def parse_let_statement
        token = @current_token
        if !expect_peek(Belial::Lexer::IDENT)
          return nil
        end
        name = Belial::Parser::ATS::Identifier.new(@current_token, @current_token.literal)

        if !expect_peek(Belial::Lexer::ASSIGN)
          return nil
        end

        # セミコロンまで読み飛ばす
        while is_a_current_token?(Belial::Lexer::SEMICOLON)
          next_token
        end
        # TODO: valueを一旦空文字列
        Belial::Parser::ATS::LetStatement.new(token, name, '')
      end

      # returnのパース
      def parse_return_statement
        token = @current_token
        next_token
        while is_a_current_token?(Belial::Lexer::SEMICOLON)
          next_token
        end
        # TODO: valueを一旦空文字列
        Belial::Parser::ATS::ReturnStatement.new(token,'')
      end

      # 式文のパース
      def parse_expression_statement
        token = @current_token
        expression = parse_expression(LOWEST)
        if is_a_peek_token?(Belial::Lexer::SEMICOLON)
          next_token
        end
        Belial::Parser::ATS::ExpressionStatement.new(token, expression)
      end

      # 前置式のパース
      def parse_prefix_expression
        token = @current_token
        operator = @current_token.literal
        next_token
        right = parse_expression(PREFIX)
        Belial::Parser::ATS::PrefixExpression.new(token, operator, right)
      end

      # 中置式のパース
      def parse_infix_expression(left)
        token = @current_token
        operator = @current_token.literal
        precedence = current_precedence
        next_token
        right = parse_expression(precedence)
        Belial::Parser::ATS::InfixExpression.new(token, left, operator, right)
      end

      def parse_integer_literal
        token = @current_token
        begin
          value = Integer(@current_token.literal)
        rescue ArgumentError  => e
          message = "could not parse #{token.literal} as integer"
          @errors << message
          return nil
        end
        Belial::Parser::ATS::IntegerLiteral.new(token, value)
      end

      def parse_expression(precedence)
        prefix = @prefix_parse_fnc[@current_token.type]
        if prefix.nil?
          no_prefix_parse_fnc_error(@current_token.type)
          return nil
        end
        left_expression = send(prefix)
        while !is_a_peek_token?(Belial::Lexer::SEMICOLON) && precedence < peek_precedence
          infix = @infix_parse_fnc[@peek_token.type]
          if infix.nil?
            return left_expression
          end
          next_token
          left_expression = send(infix, left_expression)
        end
        return left_expression
      end

      def parse_identifier
        Belial::Parser::ATS::Identifier.new(@current_token, @current_token.literal)
      end

      def is_a_current_token?(type)
        @current_token.type == type
      end

      def is_a_peek_token?(type)
        @peek_token.type == type
      end

      def expect_peek(type)
        if is_a_peek_token?(type)
          next_token
          return true
        else
          peek_error(type)
          return false
        end
      end

      def peek_precedence
        precedence = PRECEDENCES[@peek_token.type]
        if precedence.nil?
          return LOWEST
        end
        return precedence
      end

      def current_precedence
        precedence = PRECEDENCES[@current_token.type]
        if precedence.nil?
          return LOWEST
        end
        return precedence
      end

      def peek_error(type)
        @errors << "expected next token to be #{type}, got #{@peek_token.literal} instead"
      end

      def register_prefix(token_type, fnc_symbol)
        @prefix_parse_fnc[token_type] = fnc_symbol
      end

      def register_infix(token_type, fnc_symbol)
        @infix_parse_fnc[token_type] = fnc_symbol
      end

      def no_prefix_parse_fnc_error(token_type)
        msg = "no prefix parse function for #{token_type} found"
        @errors << msg
      end

      def init_prefix
        register_prefix(Belial::Lexer::IDENT, IDENTIFIER_EXPRESSION)
        register_prefix(Belial::Lexer::INT, INTEGER_EXPRESSION)
        register_prefix(Belial::Lexer::BANG, PREFIX_EXPRESSION)
        register_prefix(Belial::Lexer::MINUS, PREFIX_EXPRESSION)
      end

      def init_infix
        PRECEDENCES.each do |k, _v|
          register_infix(k, INFIX_EXPRESSION)
        end
      end
    end
  end
end
