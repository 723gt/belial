require_relative 'frame'
require_relative 'builtins'

module Belial
  module VM
    class VMError < StandardError; end

    # 値スタック1本とフレームのスタックで ISeq を実行するスタックマシン
    class VM
      ARITHMETIC = {
        add: :+,
        sub: :-,
        mul: :*,
        div: :/
      }

      COMPARISON = {
        lt: :<,
        gt: :>,
        le: :<=,
        ge: :>=
      }

      # これより深く呼び出すと無限再帰とみなして止める
      MAX_FRAMES = 10_000

      attr_reader :stack

      # out: puts / p の出力先
      def initialize(iseq = nil, debug: false, out: $stdout)
        @iseq = iseq
        @debug = debug
        @stack = []
        @frames = []
        @methods = {} # メソッド名(Symbol) => ISeq
        @builtins = Builtins.table(out)
        # 前回の run が終わったときのトップレベルの変数の値。
        # 同じ VM で続けて run すると引き継ぐ（REPL 用）
        @main_locals = []
      end

      # main の ISeq を実行し、最後の leave で返された値を返す。
      # 定義済みのメソッドとトップレベルの変数の値は、次の run に引き継がれる
      def run(iseq = @iseq)
        push_main_frame(iseq)
        execute
      rescue VMError
        # 途中で止まっても、同じ VM で次の run ができるようにする
        @stack.clear
        @frames.clear
        raise
      end

      private

      def execute
        loop do
          frame = @frames.last
          opcode, *operands = frame.iseq.insns[frame.pc]
          $stderr.puts format("%04d %s", frame.pc, [opcode, *operands.map(&:inspect)].join(" ")) if @debug
          frame.pc += 1

          case opcode
          when :putobject
            push operands[0]
          when :putnil
            push nil
          when :pop
            pop
          when :dup
            push @stack.last
          when :getlocal
            push @stack[frame.bp + operands[0]]
          when :setlocal
            @stack[frame.bp + operands[0]] = pop
          when :add, :sub, :mul, :div
            right = pop
            left = pop
            push arithmetic(opcode, left, right)
          when :eq, :neq
            right = pop
            left = pop
            push(opcode == :eq ? left == right : left != right)
          when :lt, :gt, :le, :ge
            right = pop
            left = pop
            op = COMPARISON[opcode]
            check_integer(op, left, right)
            push left.send(op, right)
          when :neg
            value = pop
            check_integer("-", value)
            push(-value)
          when :not
            push !truthy?(pop)
          when :newarray
            # 積まれた順のまま配列にする。毎回新しい配列を作る
            push @stack.pop(operands[0])
          when :index
            index = pop
            target = pop
            push index_of(target, index)
          when :jump
            frame.pc = operands[0]
          when :branchunless
            frame.pc = operands[0] unless truthy?(pop)
          when :definemethod
            name, iseq = operands
            @methods[name] = iseq
            push nil
          when :send
            name, argc = operands
            call_method(name, argc)
          when :leave
            value = pop
            finished = @frames.pop
            if @frames.empty?
              @main_locals = @stack[finished.bp, finished.iseq.locals.size]
            end
            # フレームが使っていた領域を捨てて、戻り値を積み直す
            @stack.slice!(finished.bp..)
            return value if @frames.empty?
            push value
          else
            raise VMError, "unknown instruction: #{opcode.inspect}"
          end

          $stderr.puts "     stack: #{@stack.inspect}" if @debug
        end
      end

      def push(value)
        @stack.push(value)
      end

      def pop
        @stack.pop
      end

      # Ruby と同じく false と nil だけが偽
      def truthy?(value)
        !(value.nil? || value == false)
      end

      # main のフレーム。前回の run で残ったトップレベルの変数の値をスロットに入れ直す
      def push_main_frame(iseq)
        bp = @stack.size
        iseq.locals.size.times { |i| push @main_locals[i] }
        @frames.push(Frame.new(iseq, 0, bp))
      end

      # スタックに積まれた argc 個の引数の先頭を bp にしてフレームを作る。
      # 引数がそのままローカル変数 0〜argc-1 になり、残りのローカル変数の領域を nil で確保する
      def push_frame(iseq, argc)
        raise VMError, "stack level too deep" if @frames.size >= MAX_FRAMES

        bp = @stack.size - argc
        (iseq.locals.size - argc).times { push nil }
        @frames.push(Frame.new(iseq, 0, bp))
      end

      # ユーザー定義メソッド → 組み込み関数 の順に探す。
      # ユーザー定義メソッドは新しいフレームを積むだけで、実行は execute のループがそのまま続ける。
      # 呼び出し先の leave で戻り値が引数の位置に置き換わる
      def call_method(name, argc)
        if (iseq = @methods[name])
          check_argc(name, argc, iseq.params)
          push_frame(iseq, argc)
        elsif (builtin = @builtins[name])
          arity, function = builtin
          check_argc(name, argc, arity) if arity
          args = @stack.pop(argc)
          push function.call(*args)
        else
          raise VMError, "undefined method '#{name}'"
        end
      end

      def check_argc(name, given, expected)
        return if given == expected
        raise VMError, "wrong number of arguments for '#{name}' (given #{given}, expected #{expected})"
      end

      def arithmetic(opcode, left, right)
        op = ARITHMETIC[opcode]
        # 文字列どうしの + は連結
        return left + right if opcode == :add && left.is_a?(String) && right.is_a?(String)

        check_integer(op, left, right)
        raise VMError, "divided by 0" if opcode == :div && right == 0
        # 整数の割り算は Ruby と同じく負の無限大方向に切り捨てる（-7 / 2 == -4）
        left.send(op, right)
      end

      # 配列と文字列の添字アクセス。範囲外は nil
      def index_of(target, index)
        unless (target.is_a?(Array) || target.is_a?(String)) && index.is_a?(Integer)
          raise VMError, "undefined operation '[]' for #{target.inspect}, #{index.inspect}"
        end
        target[index]
      end

      def check_integer(op, *values)
        return if values.all? { |v| v.is_a?(Integer) }
        raise VMError, "undefined operation '#{op}' for #{values.map(&:inspect).join(', ')}"
      end
    end
  end
end
