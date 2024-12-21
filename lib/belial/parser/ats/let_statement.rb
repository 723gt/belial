module Belial
  module Parser
    module ATS
      class LetStatement < ::Belial::Parser::ATS::Statement
        def initialize(token, name, value)
          @token = token
          @name = name
          @value = value
        end

        def token_literal
          @token.literal
        end
      end
    end
  end
end
