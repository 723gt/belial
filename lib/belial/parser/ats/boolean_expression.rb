module Belial
  module Parser
    module ATS
      class BooleanExpression < ::Belial::Parser::ATS::Expression
        attr_reader :token, :value

        def initialize(token, value)
          @token = token
          @value = value
        end

        def token_literal
          @token.literal
        end

        def to_string
          @token.literal
        end
      end
    end
  end
end
