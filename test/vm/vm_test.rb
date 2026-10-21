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

  def test_local_variables
    assert_run "x = 1\ny = 2\nx + y", 3
    assert_run "x = 1\nx = x + 10\nx", 11
    assert_run "a = b = 3\na + b", 6
    assert_run 'x = 5', 5
    # 右辺を読む前に宣言されるので、まだ代入されていない x は nil
    assert_run 'x = x', nil
  end

  def test_stack_is_empty_after_run_with_locals
    vm = Belial::VM::VM.new(Belial.compile("x = 1\ny = 2\nx + y"))
    assert_equal 3, vm.run
    assert_equal [], vm.stack
  end

  def test_comparison
    assert_run '1 < 2', true
    assert_run '2 < 1', false
    assert_run '1 > 2', false
    assert_run '2 >= 2', true
    assert_run '3 <= 2', false
    assert_run '1 == 1', true
    assert_run '1 != 1', false
    assert_run '1 == true', false
    assert_run 'nil == nil', true
    assert_run 'true != false', true
  end

  # false と nil だけが偽
  def test_not
    assert_run '!true', false
    assert_run '!nil', true
    assert_run '!0', false
    assert_run '!!1', true
  end

  def test_if
    assert_run "if 1 < 2\n  10\nelse\n  20\nend", 10
    assert_run "if 1 > 2\n  10\nelse\n  20\nend", 20
    assert_run "if false\n  10\nend", nil
    assert_run "if 0\n  1\nelse\n  2\nend", 1
    assert_run "if nil\n  1\nelse\n  2\nend", 2
    assert_run "y = if false\n  1\nend\ny", nil
  end

  def test_elsif
    input = <<~SRC
      x = 5
      if x < 3
        1
      elsif x < 10
        2
      else
        3
      end
    SRC
    assert_run input, 2
  end

  def test_while
    input = <<~SRC
      i = 1
      sum = 0
      while i <= 10
        sum = sum + i
        i = i + 1
      end
      sum
    SRC
    assert_run input, 55
    assert_run "while false\nend", nil
  end

  def test_nested_while
    input = <<~SRC
      count = 0
      i = 0
      while i < 3
        j = 0
        while j < 4
          count = count + 1
          j = j + 1
        end
        i = i + 1
      end
      count
    SRC
    assert_run input, 12
  end

  def test_fibonacci_loop
    input = <<~SRC
      a = 0
      b = 1
      n = 0
      while n < 10
        t = a + b
        a = b
        b = t
        n = n + 1
      end
      a
    SRC
    assert_run input, 55
  end

  def test_comparison_type_error
    error = assert_raises(Belial::VM::VMError) { Belial.run('1 < true') }
    assert_equal "undefined operation '<' for 1, true", error.message
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
