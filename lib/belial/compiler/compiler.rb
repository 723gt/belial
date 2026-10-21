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
        "/" => :div
      }

      PREFIX_INSNS = {
        "-" => :neg
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
        when AST::Infix
          insn = INFIX_INSNS[node.op] or unsupported(node)
          compile_node(node.left)
          compile_node(node.right)
          @iseq.emit(insn)
        when AST::Prefix
          insn = PREFIX_INSNS[node.op] or unsupported(node)
          compile_node(node.operand)
          @iseq.emit(insn)
        else
          unsupported(node)
        end
      end

      def unsupported(node)
        detail = node.respond_to?(:op) ? " '#{node.op}'" : ""
        raise CompileError, "#{node.class.name.split('::').last}#{detail} is not supported yet"
      end
    end
  end
end
