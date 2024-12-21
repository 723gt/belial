module Belial
  module Parser
    module ATS
      class Statement < ::Belial::Parser::ATS::Node
        def token_literal
          raise NotImplementedError
        end

        def statement_node

        end
      end
    end
  end
end
