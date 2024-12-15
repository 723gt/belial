module Belial
  module Lexer
    class Token
      attr_reader :type, :literal
      def initialize(type, literal)
        @type = type
        @literal = literal
      end
    end
  end
end
