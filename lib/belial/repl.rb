require_relative '../belial'

module Belial
  # 1入力ずつ コンパイル → 実行 して値を表示する。
  # 同じ VM を使い続けるので、前の入力で定義したメソッドや変数を次の入力でも使える
  class REPL
    PROMPT = "belial> "
    CONTINUE_PROMPT = "   ...> "

    def initialize(input: $stdin, output: $stdout, debug: false)
      @input = input
      @output = output
      @vm = VM::VM.new(debug: debug, out: output)
      @locals = [] # これまでの入力で作られたトップレベルの変数（スロット順）
    end

    def start
      loop do
        source = read_source
        break if source.nil?
        next if source.strip.empty?
        break if %w[exit quit].include?(source.strip)

        evaluate(source)
      end
      @output.puts
    end

    private

    # 1行読み、def や if が閉じていない（入力の終わりで構文エラーになる）間は続きの行を読み足す。
    # 入力の終わり（Ctrl-D）なら nil
    def read_source
      prompt(PROMPT)
      source = @input.gets
      return nil if source.nil?

      loop do
        Parser::Parser.new(source, locals: @locals).parse_program
        return source
      rescue Parser::ParseError => e
        # 途中の構文エラーは evaluate で表示する
        return source unless e.at_eof?

        prompt(CONTINUE_PROMPT)
        line = @input.gets
        return source if line.nil?
        source += line
      end
    end

    def evaluate(source)
      program = Parser::Parser.new(source, locals: @locals).parse_program
      iseq = Compiler::Compiler.new.compile(program, locals: @locals)
      value = @vm.run(iseq)
      # 実行が成功したときだけ、新しく作られた変数を覚える
      @locals = iseq.locals
      @output.puts "=> #{value.inspect}"
    rescue Parser::ParseError, Compiler::CompileError, VM::VMError => e
      @output.puts "error: #{e.message}"
    end

    def prompt(text)
      @output.print text
      @output.flush
    end
  end
end
