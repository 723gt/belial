module Belial
  module Lexer
    class Lexer
      attr_accessor :input, :position, :read_position, :ch, :line, :column

      def initialize(input)
        @input = input
        @position = 0
        @read_position = 0
        @ch = nil
        @line = 1
        @column = 0
      end
    end
  end
end
