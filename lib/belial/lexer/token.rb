module Belial
  module Lexer
    class Token
      # spaced: 直前に空白（改行・コメントを含む）があったか。括弧なし呼び出しの判定に使う
      attr_reader :type, :literal, :line, :column, :spaced
      def initialize(type, literal, line: nil, column: nil, spaced: false)
        @type = type
        @literal = literal.to_s
        @line = line
        @column = column
        @spaced = spaced
      end
    end
  end
end
