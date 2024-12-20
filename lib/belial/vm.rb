module Belial
  class VM
    EP = 4
    attr_reader :iseq, :main, :eq, :stack
    def initialize(iseq, is_debug = false)
      @iseq = iseq
      @stack = []
      @main = generate_main
      stack_info = iseq.to_a[4]
      ep_point = stack_info[:local_size] + 1
      ep_point.times { push nil}
      @ep = stack_info[:local_size]
      @is_debug = !!is_debug
    end

    def run
      iseq.to_a.last.each do |ins|
        next unless ins.is_a?(Array)
        execute(ins)
      end
    end

    def execute(ins)
      opecode = ins.first
      operand = ins[1..-1]
      $stderr.puts "==== #{opecode}(#{operand.map(&:inspect).join(', ')})" if @is_debug
      case opecode
      when :putself
        push @main
      when :putstring, :putobject, :duparray
        push operand.first
      when :send, :objtostring
        # stack ["hello world"]
        # send({:mid=>:puts, :flag=>20, :orig_argc=>1}, nil)
        call_info = operand.first # {:mid=>:puts, :flag=>20, :orig_argc=>1}
        flag = call_info[:flag]
        args = Array.new(call_info[:orig_argc]){ pop }.reverse  # args: ["hello world"]
        case flag
        when 20
          reverse = pop # main
          push reverse.send(call_info[:mid], *args) # main.send(puts, ["hello world"])
        when 16
          reverse = pop.dup
          push reverse.send(call_info[:mid], *args)
        end
      when :pop
        pop
      when :setlocal
        stack[operand[0] - @ep] = pop
      when :getlocal
        push stack[operand[0] - @ep]
      when :leave
      when :putnil
        push nil
      when :newarray
        push Array.new(operand[0]){ pop }.reverse
      when :getconstant
        # 直前にputobjectでboolをpushしている
        # そのboolをpopしてtrueならModuleから定数化する
        klass = pop
        if klass
          push Module.const_get(operand[0])
        end
      when :concatstrings
        concasts = []
        time = operand[0]
        time.times do
          concasts.push(pop)
        end
        push concasts.reverse.join
      end
      print_stack if @is_debug
    end

    def push(val)
      @stack.push(val)
    end

    def pop
      @stack.pop
    end

    def generate_main
      main = Object.new
      class << main
        def to_s
          "main"
        end
        alias inspect to_s
      end
      main
    end

    def print_stack
      $stderr.print "=====STACK"
      $stderr.print stack
      # $stderr.print stack[0...@ep]
      # $stderr.print " | "
      # $stderr.print stack[eq..-1].inspect
    end
  end
end
