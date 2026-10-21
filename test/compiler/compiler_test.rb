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

  def test_unsupported_nodes
    assert_compile_error 'x = 1', /\AAssign is not supported yet/
    assert_compile_error '1 < 2', /\AInfix '<' is not supported yet/
    assert_compile_error '!1', /\APrefix '!' is not supported yet/
    assert_compile_error 'true', /\ABoolLit is not supported yet/
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
