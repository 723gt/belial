require 'minitest/autorun'
require 'stringio'
require_relative '../../lib/belial/repl'

class REPLTest < Minitest::Test
  def test_evaluate_each_line
    assert_equal "belial> => 1\nbelial> => 3\nbelial> \n", run_repl("x = 1\nx + 2\n")
  end

  # def が閉じるまで続きの行を読む
  def test_multiline_input
    expected = "belial>    ...>    ...> => nil\nbelial> => 3\nbelial> \n"
    assert_equal expected, run_repl("def add(a, b)\n  a + b\nend\nadd 1, 2\n")
  end

  # 前の入力の変数を変数として読む（x -1 は引き算）
  def test_locals_are_kept
    assert_equal "belial> => 5\nbelial> => 4\nbelial> \n", run_repl("x = 5\nx -1\n")
  end

  def test_runtime_error_does_not_stop_repl
    assert_equal "belial> error: divided by 0\nbelial> => 2\nbelial> \n", run_repl("1 / 0\n2\n")
  end

  # エラーになった入力の代入はなかったことになる
  def test_locals_after_error
    expected = "belial> => 1\nbelial> error: divided by 0\nbelial> => 1\nbelial> \n"
    assert_equal expected, run_repl("x = 1\nx = 1 / 0\nx\n")
  end

  def test_syntax_error
    assert_equal "belial> error: 1:3: unexpected '2'\nbelial> \n", run_repl("1 2\n")
  end

  def test_input_ends_in_the_middle
    expected = "belial>    ...> error: 2:1: expected END, got end of input\nbelial> \n"
    assert_equal expected, run_repl("def f\n")
  end

  def test_puts_writes_to_output
    assert_equal "belial> hi\n=> nil\nbelial> \n", run_repl("puts \"hi\"\n")
  end

  def test_blank_line
    assert_equal "belial> belial> => 1\nbelial> \n", run_repl("\n1\n")
  end

  def test_exit
    assert_equal "belial> \n", run_repl("exit\n1\n")
  end

  private

  def run_repl(input)
    output = StringIO.new
    Belial::REPL.new(input: StringIO.new(input), output: output).start
    output.string
  end
end
