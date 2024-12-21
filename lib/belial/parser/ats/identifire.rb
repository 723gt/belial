module Belial
  module Parser
    module ATS
      class Identifier < ::Belial::Parser::ATS::Expression
        def initialize(token, value)
          @token = token
          @value = value
        end

        def token_literal
          @token.literal
        end
      end
    end
  end
end
