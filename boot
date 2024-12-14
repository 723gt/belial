#!/usr/bin/env ruby

$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)

require "belial/vm"

iseq = RubyVM::InstructionSequence.compile_file(ARGV[0], false)
Belial::VM.new(iseq).run
