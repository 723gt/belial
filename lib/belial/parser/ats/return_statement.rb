module Belial
  module Parser
    module ATS
      class ReturnStatement < ::Belial::Parser::ATS::Statement
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
