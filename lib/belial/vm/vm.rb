require_relative 'frame'

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

      def initialize(iseq, debug: false)
        @iseq = iseq
        @debug = debug
        @stack = []
        @frames = []
        @methods = {} # メソッド名(Symbol) => ISeq
      end

      # main の ISeq を実行し、最後の leave で返された値を返す
      def run
        push_frame(@iseq)
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

      private

      def push(value)
        @stack.push(value)
      end

      def pop
        @stack.pop
      end

      # スタックに積まれた argc 個の引数の先頭を bp にしてフレームを作る。
      # 引数がそのままローカル変数 0〜argc-1 になり、残りのローカル変数の領域を nil で確保する
      def push_frame(iseq, argc = 0)
        raise VMError, "stack level too deep" if @frames.size >= MAX_FRAMES

        bp = @stack.size - argc
        (iseq.locals.size - argc).times { push nil }
        @frames.push(Frame.new(iseq, 0, bp))
      end

      # 新しいフレームを積むだけで、実行は run のループがそのまま続ける。
      # 呼び出し先の leave で戻り値が引数の位置に置き換わる
      def call_method(name, argc)
        iseq = @methods[name]
        raise VMError, "undefined method '#{name}'" unless iseq
        if argc != iseq.params
          raise VMError, "wrong number of arguments for '#{name}' (given #{argc}, expected #{iseq.params})"
        end
        push_frame(iseq, argc)
      end

      # Ruby と同じく false と nil だけが偽
      def truthy?(value)
        !(value.nil? || value == false)
      end

      def arithmetic(opcode, left, right)
        op = ARITHMETIC[opcode]
        check_integer(op, left, right)
        raise VMError, "divided by 0" if opcode == :div && right == 0
        # 整数の割り算は Ruby と同じく負の無限大方向に切り捨てる（-7 / 2 == -4）
        left.send(op, right)
      end

      def check_integer(op, *values)
        return if values.all? { |v| v.is_a?(Integer) }
        raise VMError, "undefined operation '#{op}' for #{values.map(&:inspect).join(', ')}"
      end
    end
  end
end
