require 'minitest/autorun'
require_relative '../../lib/belial'

class CompilerTest < Minitest::Test
  def test_integer
    assert_disasm '1', <<~ISEQ
      == main
      0000 putobject 1
      0001 leave
    ISEQ
  end

  def test_empty_program
    assert_disasm '', <<~ISEQ
      == main
      0000 putnil
      0001 leave
    ISEQ
  end

  def test_arithmetic
    assert_disasm '1 + 2 * 3', <<~ISEQ
      == main
      0000 putobject 1
      0001 putobject 2
      0002 putobject 3
      0003 mul
      0004 add
      0005 leave
    ISEQ
  end

  def test_prefix_minus
    assert_disasm '-(1 - 2) / 3', <<~ISEQ
      == main
      0000 putobject 1
      0001 putobject 2
      0002 sub
      0003 neg
      0004 putobject 3
      0005 div
      0006 leave
    ISEQ
  end

  # 最後以外の文の値は pop で捨てる
  def test_multiple_statements
    assert_disasm "1 + 2\n3\n4", <<~ISEQ
      == main
      0000 putobject 1
      0001 putobject 2
      0002 add
      0003 pop
      0004 putobject 3
      0005 pop
      0006 putobject 4
      0007 leave
    ISEQ
  end

  # 代入は値を残すため dup してから setlocal する
  def test_assign_and_local_variable
    assert_disasm "x = 1\nx + 2", <<~ISEQ
      == main
      0000 putobject 1
      0001 dup
      0002 setlocal 0
      0003 pop
      0004 getlocal 0
      0005 putobject 2
      0006 add
      0007 leave
    ISEQ
  end

  def test_local_slots
    iseq = Belial.compile("a = 1\nb = 2\na = 3")
    assert_equal ["a", "b"], iseq.locals
  end

  def test_comparison_and_not
    assert_disasm '!(1 <= 2)', <<~ISEQ
      == main
      0000 putobject 1
      0001 putobject 2
      0002 le
      0003 not
      0004 leave
    ISEQ
  end

  def test_if_elsif_else
    input = <<~SRC
      if true
        1
      elsif false
        2
      else
        3
      end
    SRC
    assert_disasm input, <<~ISEQ
      == main
      0000 putobject true
      0001 branchunless 4
      0002 putobject 1
      0003 jump 9
      0004 putobject false
      0005 branchunless 8
      0006 putobject 2
      0007 jump 9
      0008 putobject 3
      0009 leave
    ISEQ
  end

  # else がなければ偽のときの値は nil
  def test_if_without_else
    assert_disasm "if 1 < 2\n  3\nend", <<~ISEQ
      == main
      0000 putobject 1
      0001 putobject 2
      0002 lt
      0003 branchunless 6
      0004 putobject 3
      0005 jump 7
      0006 putnil
      0007 leave
    ISEQ
  end

  def test_while
    input = <<~SRC
      i = 0
      while i < 3
        i = i + 1
      end
    SRC
    assert_disasm input, <<~ISEQ
      == main
      0000 putobject 0
      0001 dup
      0002 setlocal 0
      0003 pop
      0004 getlocal 0
      0005 putobject 3
      0006 lt
      0007 branchunless 15
      0008 getlocal 0
      0009 putobject 1
      0010 add
      0011 dup
      0012 setlocal 0
      0013 pop
      0014 jump 4
      0015 putnil
      0016 leave
    ISEQ
  end

  # メソッドの本体は別の ISeq になり、disasm では main の後ろに続く
  def test_def_and_call
    input = <<~SRC
      def add(x, y)
        x + y
      end
      add(1, 2)
    SRC
    assert_disasm input, <<~ISEQ
      == main
      0000 definemethod :add <iseq add>
      0001 pop
      0002 putobject 1
      0003 putobject 2
      0004 send :add 2
      0005 leave

      == add
      0000 getlocal 0
      0001 getlocal 1
      0002 add
      0003 leave
    ISEQ
  end

  def test_method_locals_start_with_params
    iseq = Belial.compile("def f(a, b)\n  c = a\nend")
    method_iseq = iseq.insns[0][2]
    assert_equal 2, method_iseq.params
    assert_equal ["a", "b", "c"], method_iseq.locals
    assert_equal [], iseq.locals
  end

  def test_zero_arg_call
    assert_disasm "def one\n  1\nend\none", <<~ISEQ
      == main
      0000 definemethod :one <iseq one>
      0001 pop
      0002 send :one 0
      0003 leave

      == one
      0000 putobject 1
      0001 leave
    ISEQ
  end

  # return はその場で leave する
  def test_return
    input = <<~SRC
      def f(n)
        if n < 1
          return 0
        end
        n
      end
    SRC
    assert_disasm input, <<~ISEQ
      == main
      0000 definemethod :f <iseq f>
      0001 leave

      == f
      0000 getlocal 0
      0001 putobject 1
      0002 lt
      0003 branchunless 7
      0004 putobject 0
      0005 leave
      0006 jump 8
      0007 putnil
      0008 pop
      0009 getlocal 0
      0010 leave
    ISEQ
  end

  def test_return_without_value
    assert_disasm 'return', <<~ISEQ
      == main
      0000 putnil
      0001 leave
      0002 leave
    ISEQ
  end

  def test_string_array_and_index
    assert_disasm '["a", [1]][0]', <<~ISEQ
      == main
      0000 putobject "a"
      0001 putobject 1
      0002 newarray 1
      0003 newarray 2
      0004 putobject 0
      0005 index
      0006 leave
    ISEQ
  end

  def test_builtin_call
    assert_disasm 'puts "hi"', <<~ISEQ
      == main
      0000 putobject "hi"
      0001 send :puts 1
      0002 leave
    ISEQ
  end

  # REPL 用: すでにある変数は同じスロットのまま、新しい変数はその後ろに入る
  def test_compile_with_existing_locals
    program = Belial::Parser::Parser.new("y = x", locals: ["x"]).parse_program
    iseq = Belial::Compiler::Compiler.new.compile(program, locals: ["x"])
    assert_equal ["x", "y"], iseq.locals
    assert_equal [:getlocal, 0], iseq.insns[0]
  end

  UnknownNode = Struct.new(:value)

  def test_unknown_node
    program = Belial::AST::Program.new([UnknownNode.new(1)])
    error = assert_raises(Belial::Compiler::CompileError) { Belial::Compiler::Compiler.new.compile(program) }
    assert_equal "UnknownNode is not supported yet", error.message
  end

  private

  def assert_disasm(source, expected)
    assert_equal expected.chomp, Belial.compile(source).disasm
  end

  def assert_compile_error(source, message)
    error = assert_raises(Belial::Compiler::CompileError) { Belial.compile(source) }
    assert_match message, error.message
  end
end
