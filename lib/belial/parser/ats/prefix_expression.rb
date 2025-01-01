require './lib/belial/parser/ats/expression'

module Belial
  module Parser
    module ATS
      class PrefixExpression < ::Belial::Parser::ATS::Expression
        attr_reader :token, :operator, :right

        def initialize(token, operator, right)
          @token = token
          @operator = operator
          @right = right # Expression
        end

        def token_literal
          @token.literal
        end
      end
    end
  end
end
