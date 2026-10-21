require_relative 'belial/parser/parser'
require_relative 'belial/compiler/compiler'
require_relative 'belial/vm/vm'

module Belial
  # ソース → AST → ISeq
  def self.compile(source)
    program = Parser::Parser.new(source).parse_program
    Compiler::Compiler.new.compile(program)
  end

  # ソースを実行し、最後に評価した式の値を返す
  def self.run(source, debug: false)
    VM::VM.new(compile(source), debug: debug).run
  end
end
