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

      attr_reader :stack

      def initialize(iseq, debug: false)
        @iseq = iseq
        @debug = debug
        @stack = []
        @frames = []
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

      # 現在のスタックの先頭を bp にしてフレームを作り、ローカル変数の領域を nil で確保する
      def push_frame(iseq)
        bp = @stack.size
        iseq.locals.size.times { push nil }
        @frames.push(Frame.new(iseq, 0, bp))
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
