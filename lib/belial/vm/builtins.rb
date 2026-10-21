module Belial
  module VM
    # 組み込み関数。名前(Symbol) => [引数の数（nil なら可変長）, 処理]
    # 同じ名前のメソッドを def すると、そちらが優先される
    module Builtins
      def self.table(out)
        {
          # 引数を1つずつ行に出力する。配列は要素ごとに、nil は空行（Ruby の puts と同じ）
          puts: [nil, lambda do |*args|
            out.puts(*args)
            nil
          end],

          # inspect した形で出力し、引数をそのまま返す
          p: [nil, lambda do |*args|
            args.each { |arg| out.puts(arg.inspect) }
            args.size <= 1 ? args.first : args
          end],

          len: [1, lambda do |value|
            unless value.is_a?(Array) || value.is_a?(String)
              raise VMError, "undefined operation 'len' for #{value.inspect}"
            end
            value.size
          end],

          # 配列の末尾に追加し、その配列を返す（配列そのものを書き換える）
          push: [2, lambda do |array, value|
            raise VMError, "undefined operation 'push' for #{array.inspect}" unless array.is_a?(Array)
            array.push(value)
          end]
        }
      end
    end
  end
end
