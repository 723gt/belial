module Belial
  module Parser
    module ATS
      class Expression < ::Belial::Parser::ATS::Node
        def token_literal
          raise NotImplementedError
        end

        def expression_node

        end
      end
    end
  end
end
