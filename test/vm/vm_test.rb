require 'minitest/autorun'
require_relative '../../lib/belial'

class VMTest < Minitest::Test
  def test_integer
    assert_run '42', 42
  end

  def test_empty_program
    assert_run '', nil
  end

  def test_arithmetic
    assert_run '1 + 2', 3
    assert_run '5 - 8', -3
    assert_run '6 * 7', 42
    assert_run '7 / 2', 3
    assert_run '1 + 2 * 3', 7
    assert_run '(1 + 2) * 3', 9
    assert_run '10 - 3 - 2', 5
    assert_run '100 / 10 / 5', 2
  end

  def test_prefix_minus
    assert_run '-5 + 2', -3
    assert_run '- -3', 3
    assert_run '-(2 * 3)', -6
  end

  # 整数の割り算は Ruby と同じく負の無限大方向に切り捨てる
  def test_division_rounds_toward_negative_infinity
    assert_run '-7 / 2', -4
    assert_run '7 / -2', -4
  end

  def test_last_statement_is_result
    assert_run "1 + 1\n2 * 2\n3 * 3", 9
  end

  # 実行後に値スタックに何も残らない
  def test_stack_is_empty_after_run
    vm = Belial::VM::VM.new(Belial.compile("1 + 2\n3 * 4\n5"))
    assert_equal 5, vm.run
    assert_equal [], vm.stack
  end

  def test_division_by_zero
    error = assert_raises(Belial::VM::VMError) { Belial.run('1 / 0') }
    assert_equal 'divided by 0', error.message
  end

  def test_type_error
    iseq = Belial::Compiler::ISeq.new("main")
    iseq.emit(:putobject, 1)
    iseq.emit(:putobject, "a")
    iseq.emit(:add)
    iseq.emit(:leave)
    error = assert_raises(Belial::VM::VMError) { Belial::VM::VM.new(iseq).run }
    assert_equal %q(undefined operation '+' for 1, "a"), error.message
  end

  def test_unknown_instruction
    iseq = Belial::Compiler::ISeq.new("main")
    iseq.emit(:nop)
    assert_raises(Belial::VM::VMError) { Belial::VM::VM.new(iseq).run }
  end

  def test_debug_output
    _, err = capture_io { Belial.run('1 + 2', debug: true) }
    expected = <<~OUT
      0000 putobject 1
           stack: [1]
      0001 putobject 2
           stack: [1, 2]
      0002 add
           stack: [3]
      0003 leave
    OUT
    assert_equal expected, err
  end

  private

  def assert_run(source, expected)
    if expected.nil?
      assert_nil Belial.run(source), "source: #{source.inspect}"
    else
      assert_equal expected, Belial.run(source), "source: #{source.inspect}"
    end
  end
end
