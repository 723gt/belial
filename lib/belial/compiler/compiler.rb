require_relative '../parser/ast'
require_relative 'iseq'

module Belial
  module Compiler
    class CompileError < StandardError; end

    # AST をたどって ISeq に命令を出す。
    # 各式のコンパイル結果は「実行後にスタックへ値を1つ積む」命令列になる
    class Compiler
      INFIX_INSNS = {
        "+" => :add,
        "-" => :sub,
        "*" => :mul,
        "/" => :div,
        "==" => :eq,
        "!=" => :neq,
        "<" => :lt,
        ">" => :gt,
        "<=" => :le,
        ">=" => :ge
      }

      PREFIX_INSNS = {
        "-" => :neg,
        "!" => :not
      }

      def compile(program)
        @iseq = ISeq.new("main")
        compile_body(program.body)
        @iseq.emit(:leave)
        @iseq
      end

      private

      # 文の並び。最後の文の値だけをスタックに残す（空なら nil）
      def compile_body(body)
        if body.empty?
          @iseq.emit(:putnil)
          return
        end
        body.each_with_index do |node, i|
          compile_node(node)
          @iseq.emit(:pop) unless i == body.size - 1
        end
      end

      def compile_node(node)
        case node
        when AST::IntLit
          @iseq.emit(:putobject, node.value)
        when AST::BoolLit
          @iseq.emit(:putobject, node.value)
        when AST::NilLit
          @iseq.emit(:putnil)
        when AST::LocalVar
          @iseq.emit(:getlocal, @iseq.local_index(node.name))
        when AST::Assign
          compile_assign(node)
        when AST::Infix
          insn = INFIX_INSNS[node.op] or unsupported(node)
          compile_node(node.left)
          compile_node(node.right)
          @iseq.emit(insn)
        when AST::Prefix
          insn = PREFIX_INSNS[node.op] or unsupported(node)
          compile_node(node.operand)
          @iseq.emit(insn)
        when AST::If
          compile_if(node)
        when AST::While
          compile_while(node)
        when AST::Def
          compile_def(node)
        when AST::Call
          node.args.each { |arg| compile_node(arg) }
          @iseq.emit(:send, node.name.to_sym, node.args.size)
        when AST::Return
          node.value ? compile_node(node.value) : @iseq.emit(:putnil)
          @iseq.emit(:leave)
        else
          unsupported(node)
        end
      end

      # メソッド本体を別の ISeq にコンパイルし、definemethod で登録する（def 自体の値は nil）。
      # 引数はローカル変数の先頭 params 個のスロットになる
      def compile_def(node)
        outer = @iseq
        @iseq = ISeq.new(node.name, params: node.params.size, locals: node.params.dup)
        compile_body(node.body)
        @iseq.emit(:leave)
        method_iseq = @iseq
        @iseq = outer
        @iseq.emit(:definemethod, node.name.to_sym, method_iseq)
      end

      # 代入も式なので、代入した値をスタックに残す（dup してから setlocal）
      def compile_assign(node)
        # 右辺より先にスロットを割り当てる（x = x の右辺の x もこのスロットを読む）
        index = @iseq.local_index(node.name)
        compile_node(node.value)
        @iseq.emit(:dup)
        @iseq.emit(:setlocal, index)
      end

      #   cond
      #   branchunless ELSE1
      #   then_body
      #   jump END
      # ELSE1:
      #   elsif の cond / branchunless ELSE2 / body / jump END
      # ELSE2:
      #   else_body（なければ putnil）
      # END:
      def compile_if(node)
        branches = [[node.cond, node.then_body], *node.elsifs]
        end_jumps = []

        branches.each do |cond, body|
          compile_node(cond)
          branch = @iseq.emit(:branchunless, nil)
          compile_body(body)
          end_jumps << @iseq.emit(:jump, nil)
          @iseq.patch(branch, @iseq.next_index)
        end

        compile_body(node.else_body || [])
        end_jumps.each { |jump| @iseq.patch(jump, @iseq.next_index) }
      end

      # COND:
      #   cond
      #   branchunless END
      #   body
      #   pop
      #   jump COND
      # END:
      #   putnil（while 自体の値は nil）
      def compile_while(node)
        cond_index = @iseq.next_index
        compile_node(node.cond)
        branch = @iseq.emit(:branchunless, nil)
        compile_body(node.body)
        @iseq.emit(:pop)
        @iseq.emit(:jump, cond_index)
        @iseq.patch(branch, @iseq.next_index)
        @iseq.emit(:putnil)
      end

      def unsupported(node)
        detail = node.respond_to?(:op) ? " '#{node.op}'" : ""
        raise CompileError, "#{node.class.name.split('::').last}#{detail} is not supported yet"
      end
    end
  end
end
