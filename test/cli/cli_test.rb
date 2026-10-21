require 'minitest/autorun'
require 'open3'
require 'rbconfig'

# bin/belial を別プロセスで起動して確かめる
class CLITest < Minitest::Test
  BIN = File.expand_path('../../bin/belial', __dir__)
  EXAMPLE = File.expand_path('../../examples/phase1.bl', __dir__)

  def test_run_file
    out, err, status = belial(EXAMPLE)
    assert status.success?, err
    assert_equal "0\n1\n1\n2\n3\n5\n8\n13\n21\n34\n3\ntrue\nhello\n", out
  end

  def test_run_code
    out, _, status = belial("-e", "puts 1 + 2")
    assert status.success?
    assert_equal "3\n", out
  end

  def test_disasm
    out, _, status = belial("--disasm", "-e", "1 + 2")
    assert status.success?
    assert_equal "== main\n0000 putobject 1\n0001 putobject 2\n0002 add\n0003 leave\n", out
  end

  def test_debug
    out, err, status = belial("-d", "-e", "1")
    assert status.success?
    assert_equal "", out
    assert_equal "0000 putobject 1\n     stack: [1]\n0001 leave\n", err
  end

  def test_syntax_error
    _, err, status = belial("-e", "1 2")
    refute status.success?
    assert_equal "-e:1:3: unexpected '2'\n", err
  end

  def test_runtime_error
    out, err, status = belial("-e", "puts 1\n1 / 0")
    refute status.success?
    assert_equal "1\n", out
    assert_equal "-e: divided by 0\n", err
  end

  def test_repl
    out, _, status = belial(stdin: "1 + 2\n")
    assert status.success?
    assert_equal "belial> => 3\nbelial> \n", out
  end

  private

  def belial(*args, stdin: "")
    out, err, status = Open3.capture3(RbConfig.ruby, BIN, *args, stdin_data: stdin)
    # Windows では改行が \r\n になることがあるのでそろえる
    [out.gsub("\r\n", "\n"), err.gsub("\r\n", "\n"), status]
  end
end
