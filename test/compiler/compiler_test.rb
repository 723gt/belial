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

  def test_unsupported_nodes
    assert_compile_error "def f\nend", /\ADef is not supported yet/
    assert_compile_error 'foo', /\ACall is not supported yet/
    assert_compile_error '"a"', /\AStrLit is not supported yet/
    assert_compile_error '[1]', /\AArrayLit is not supported yet/
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
