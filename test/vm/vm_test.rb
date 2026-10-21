require 'minitest/autorun'
require 'stringio'
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

  def test_method_call
    assert_run "def add(a, b)\n  a + b\nend\nadd(1, 2)", 3
    # 引数は左から順に渡る
    assert_run "def sub(a, b)\n  a - b\nend\nsub(10, 3)", 7
    # 括弧なし呼び出し・0引数呼び出し
    assert_run "def add(a, b)\n  a + b\nend\nadd 1, 2", 3
    assert_run "def hello\n  42\nend\nhello", 42
  end

  def test_def_and_empty_method_return_nil
    assert_run "def f\nend", nil
    assert_run "def f\nend\nf", nil
  end

  def test_recursion
    input = <<~SRC
      def fib(n)
        if n < 2
          return n
        end
        fib(n - 1) + fib(n - 2)
      end
      fib(15)
    SRC
    assert_run input, 610
  end

  # if も式なので、最後に評価した分岐の値がメソッドの戻り値になる
  def test_implicit_return
    input = <<~SRC
      def fact(n)
        if n <= 1
          1
        else
          n * fact(n - 1)
        end
      end
      fact(10)
    SRC
    assert_run input, 3628800
  end

  # メソッドのローカル変数はトップレベルの変数と別物
  def test_method_has_own_locals
    input = <<~SRC
      x = 100
      def f(y)
        x = y * 2
        x + 1
      end
      f(5) + x
    SRC
    assert_run input, 111
  end

  def test_return_from_while
    input = <<~SRC
      def first_over(limit)
        i = 0
        while true
          if i * i > limit
            return i
          end
          i = i + 1
        end
      end
      first_over(50)
    SRC
    assert_run input, 8
  end

  def test_top_level_return
    assert_run "return 1\n2", 1
  end

  def test_redefine_method
    assert_run "def f\n  1\nend\ndef f\n  2\nend\nf", 2
  end

  def test_stack_is_empty_after_calls
    source = "def fib(n)\n  if n < 2\n    return n\n  end\n  fib(n - 1) + fib(n - 2)\nend\nfib(10)"
    vm = Belial::VM::VM.new(Belial.compile(source))
    assert_equal 55, vm.run
    assert_equal [], vm.stack
  end

  def test_undefined_method
    error = assert_raises(Belial::VM::VMError) { Belial.run('foo') }
    assert_equal "undefined method 'foo'", error.message
    # 定義より前の呼び出し
    assert_raises(Belial::VM::VMError) { Belial.run("f\ndef f\n  1\nend") }
  end

  def test_wrong_number_of_arguments
    error = assert_raises(Belial::VM::VMError) { Belial.run("def f(a)\n  a\nend\nf(1, 2)") }
    assert_equal "wrong number of arguments for 'f' (given 2, expected 1)", error.message
  end

  def test_stack_level_too_deep
    error = assert_raises(Belial::VM::VMError) { Belial.run("def f(n)\n  f(n + 1)\nend\nf(0)") }
    assert_equal "stack level too deep", error.message
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

  def test_string
    assert_run '"abc"', "abc"
    assert_run '"a" + "b"', "ab"
    assert_run '"a" == "a"', true
    assert_run '"a" != "b"', true
    assert_run '"abc"[1]', "b"
    error = assert_raises(Belial::VM::VMError) { Belial.run('"a" + 1') }
    assert_equal %q(undefined operation '+' for "a", 1), error.message
  end

  def test_array
    assert_run '[1, 2 + 3, "x"]', [1, 5, "x"]
    assert_run '[]', []
    assert_run '[[1, 2], [3]][0][1]', 2
    assert_run "xs = [10, 20]\nxs[1]", 20
    # 範囲外は nil
    assert_run "xs = [10, 20]\nxs[5]", nil
    assert_run '[1] == [1]', true
  end

  def test_index_errors
    assert_raises(Belial::VM::VMError) { Belial.run('1[0]') }
    assert_raises(Belial::VM::VMError) { Belial.run('[1]["a"]') }
  end

  # 配列リテラルは評価するたびに新しい配列を作る
  def test_array_literal_creates_new_array
    input = <<~SRC
      def make
        [1]
      end
      a = make
      push(a, 2)
      len(make)
    SRC
    assert_run input, 1
  end

  def test_puts
    out = StringIO.new
    result = Belial.run('puts 1, "a", nil, [2, 3]', out: out)
    assert_nil result
    assert_equal "1\na\n\n2\n3\n", out.string

    out = StringIO.new
    Belial.run('puts', out: out)
    assert_equal "\n", out.string
  end

  def test_p
    out = StringIO.new
    assert_equal "a", Belial.run('p "a"', out: out)
    assert_equal %Q("a"\n), out.string

    out = StringIO.new
    assert_equal [1, nil], Belial.run('p 1, nil', out: out)
    assert_equal "1\nnil\n", out.string
  end

  def test_len_and_push
    assert_run 'len([1, 2, 3])', 3
    assert_run 'len("hello")', 5
    assert_run "xs = [1]\npush(xs, 2)\nxs", [1, 2]
    error = assert_raises(Belial::VM::VMError) { Belial.run('len(1)') }
    assert_equal "undefined operation 'len' for 1", error.message
    assert_raises(Belial::VM::VMError) { Belial.run('push(1, 2)') }
  end

  def test_builtin_wrong_number_of_arguments
    error = assert_raises(Belial::VM::VMError) { Belial.run('len(1, 2)') }
    assert_equal "wrong number of arguments for 'len' (given 2, expected 1)", error.message
  end

  # 同じ名前のメソッドを定義すると組み込み関数より優先される
  def test_method_overrides_builtin
    assert_run "def len(x)\n  0\nend\nlen([1])", 0
  end

  # 同じ VM で続けて run すると、メソッドとトップレベルの変数を引き継ぐ（REPL 用）
  def test_run_keeps_state
    vm = Belial::VM::VM.new
    compile = lambda do |source, locals|
      program = Belial::Parser::Parser.new(source, locals: locals).parse_program
      Belial::Compiler::Compiler.new.compile(program, locals: locals)
    end

    first = compile.call("x = 10\ndef double(n)\n  n * 2\nend", [])
    vm.run(first)
    second = compile.call("double(x) + 1", first.locals)
    assert_equal 21, vm.run(second)
  end

  # 途中でエラーになっても、同じ VM で次の run ができる
  def test_run_after_error
    vm = Belial::VM::VM.new
    assert_raises(Belial::VM::VMError) { vm.run(Belial.compile("1 + (2 / 0)")) }
    assert_equal [], vm.stack
    assert_equal 3, vm.run(Belial.compile("1 + 2"))
  end

  # docs/phase1.md の到達目標のサンプル
  def test_phase1_example
    out = StringIO.new
    source = File.read(File.expand_path('../../examples/phase1.bl', __dir__), encoding: "UTF-8")
    Belial.run(source, out: out)
    assert_equal "0\n1\n1\n2\n3\n5\n8\n13\n21\n34\n3\ntrue\nhello\n", out.string
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
