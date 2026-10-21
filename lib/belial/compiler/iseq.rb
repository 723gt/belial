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

      # 命令を追加し、その命令の番号を返す
      def emit(opcode, *operands)
        insns << [opcode, *operands]
        insns.size - 1
      end

      # 次に追加される命令の番号（ジャンプ先として使う）
      def next_index
        insns.size
      end

      # 先に出しておいたジャンプ命令（jump / branchunless）の飛び先を後から埋める
      def patch(index, addr)
        insns[index][1] = addr
      end

      # ローカル変数のスロット番号。初めての名前なら新しいスロットを割り当てる
      def local_index(name)
        locals << name unless locals.include?(name)
        locals.index(name)
      end

      # 命令列を読める形の文字列にする。definemethod で参照しているメソッドの命令列も後ろに続ける
      #   == main
      #   0000 definemethod :one <iseq one>
      #   0001 leave
      #
      #   == one
      #   0000 putobject 1
      #   0001 leave
      def disasm
        lines = ["== #{name}"]
        children = []
        insns.each_with_index do |(opcode, *operands), i|
          children.concat(operands.grep(self.class))
          lines << format("%04d %s", i, [opcode, *operands.map(&:inspect)].join(" "))
        end
        [lines.join("\n"), *children.map(&:disasm)].join("\n\n")
      end

      # 命令のオペランドやデバッグ表示で中身を全部出さないようにする
      def inspect
        "<iseq #{name}>"
      end
    end
  end
end
