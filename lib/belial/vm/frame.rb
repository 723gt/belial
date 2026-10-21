module Belial
  module VM
    # 実行中の ISeq 1つ分の状態
    # pc: 次に実行する命令の番号
    # bp: このフレームが使う値スタックの先頭位置。bp から locals.size 個がローカル変数の領域
    Frame = Struct.new(:iseq, :pc, :bp)
  end
end
