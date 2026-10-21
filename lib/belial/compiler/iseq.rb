module Belial
  module Compiler
    # 命令列オブジェクト
    # name:   "main" や メソッド名
    # params: 引数の数
    # locals: ローカル変数名の表（index = 変数スロット番号。先頭 params 個は引数）
    # insns:  [[:putobject, 1], [:add], ...]
    ISeq = Struct.new(:name, :params, :locals, :insns) do
      def initialize(name, params: 0, locals: [], insns: [])
        super(name, params, locals, insns)
      end

      def emit(opcode, *operands)
        insns << [opcode, *operands]
      end

      # 命令列を読める形の文字列にする
      #   == main
      #   0000 putobject 1
      #   0001 leave
      def disasm
        lines = ["== #{name}"]
        insns.each_with_index do |(opcode, *operands), i|
          lines << format("%04d %s", i, [opcode, *operands.map(&:inspect)].join(" "))
        end
        lines.join("\n")
      end
    end
  end
end
