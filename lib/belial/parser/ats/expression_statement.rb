require './lib/belial/parser/ats/statement'
module Belial
  module Parser
    module ATS
      class ExpressionStatement < ::Belial::Parser::ATS::Statement
        attr_reader :token, :expression
        def initialize(token, expression)
          @token = token
          @expression = expression
        end

        def token_literal
          @token.literal
        end
      end
    end
  end
end
