module Belial
  module Parser
    module ATS
      class Program
        attr_reader :statements
        def initialize
          @statements = []
        end

        def token_literal
          if @statements.empty?
            ''
          else
            @statements.first.token_literal
          end
        end

        def add_statement(statement)
          @statements << statement
        end
      end
    end
  end
end
