require './lib/belial/parser/ats/statement'
module Belial
  module Parser
    module ATS
      class LetStatement < ::Belial::Parser::ATS::Statement
        attr_reader :token, :name, :value
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
