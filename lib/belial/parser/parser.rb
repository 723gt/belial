require './lib/belial/parser/ats/program'
require './lib/belial/parser/ats/let_statement'
require './lib/belial/parser/ats/identifier'
require './lib/belial/lexer/token'
module Belial
  module Parser
    class Parser
      def initialize(lexical_analyzer)
        @lexer = lexical_analyzer
        @current_token = nil
        @peek_token = nil

        next_token
        next_token
      end

      def next_token
        @current_token = @peek_token
        @peek_token = @lexer.next_token
      end

      def parser_program
        program = Belial::Parser::ATS::Program.new
        while @current_token.type != Belial::Lexer::EOF
          stm = parser_statement
          if !stm.nil?
            program.add_statement(stm)
          end
          next_token
        end
        return program
      end

      def parser_statement
        case @current_token.type
        when Belial::Lexer::LET
          return parser_let_statement
        else
          return nil
        end
      end

      private
      def parser_let_statement
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
          return false
        end
      end
    end
  end
end
