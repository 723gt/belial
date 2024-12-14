#!/usr/bin/env ruby
require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: script.rb [options]"
  opts.on("-d", "--debug", "Enable debug mode") do
    options[:debug] = true
  end
end.parse!

$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)

require "belial/vm"

iseq = RubyVM::InstructionSequence.compile_file(ARGV[0], false)
Belial::VM.new(iseq, options[:debug]).run
