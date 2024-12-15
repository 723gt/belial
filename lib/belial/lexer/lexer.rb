module Belial
  module Lexer
    class Lexer
      attr_accessor :input, :position, :read_position, :ch

      def initialize(input)
        @input = input
        @position = 0
        @read_position = 0
        @ch = ""
      end
    end
  end
end
