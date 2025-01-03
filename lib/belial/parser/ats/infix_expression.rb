module Belial
  module Parser
    module ATS
      class InfixExpression < ::Belial::Parser::ATS::Expression
        attr_reader :token, :left, :operator, :right

        def initialize(token, left, operator, right)
          @token = token # 演算子
          @left = left
          @operator = operator
          @right = right
        end

        def token_literal
          @token.literal
        end

        def to_string
          "(#{left.to_string} #{operator} #{right.to_string})"
        end
      end
    end
  end
end
