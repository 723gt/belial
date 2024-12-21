module Belial
  module Parser
    module ATS
      class Program
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
      end
    end
  end
end
