module Belial
  module Parser
    class Parser
      def initialize(lexical_analyzer)
        @lexer = lexical_analyzer
        @current_token = nil
        @peek_token = nil

        @lexer.nextToken
        @lexer.nextToken
      end

      def next_token
        @current_token = @peek_token
        @peek_token = @lexer.next_token
      end

      def parser_program
        return nil
      end
    end
  end
end
