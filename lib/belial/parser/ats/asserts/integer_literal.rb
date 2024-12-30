require './lib/belial/parser/ats/expression'
module Belial
  module Parser
    module ATS
      class IntegerLiteral < ::Belial::Parser::ATS::Expression
        attr_reader :token, :value
        def initialize(token, value)
         @token = token
         @value = value
        end

        def token_literal
         @token.literal
        end

        def to_string
           @value
        end
      end
    end
  end
end
