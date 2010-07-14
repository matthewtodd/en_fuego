ENV['RACK_ENV'] = 'test'
require 'test/unit'

require 'rubygems'
require 'bundler'
Bundler.require(:default, :test)
$:.unshift File.expand_path('../../lib', __FILE__)
require 'en_fuego'


# These tweaks make backtraces WAY easier to read!
module Test::Unit
  module Util::BacktraceFilter
    ROOT = File.expand_path('../..', __FILE__)

    def filter_backtrace(backtrace, prefix=nil)
      #return backtrace.reverse # useful if something goes wonky

      backtrace.collect { |line| line.sub(ROOT, '.') }.
                select  { |line| line.start_with?('.') }.
                reject  { |line| line.include?('vendor') }.
                collect { |line| format_backtrace(line) }.
                collect { |line| color_backtrace(line) }.
                reverse
    end

    def color_backtrace(line)
      color = line.start_with?('./lib') ? 44 : 0
      "\e[#{color}m#{line}\e[0m"
    end

    def format_backtrace(line)
      parts = line.split(':')

      format = '%-34.34s line %-4.4s'
      format << ' %s' if parts.length > 2
      format % parts
    end
  end

  class Error
    def long_display
      backtrace = filter_backtrace(@exception.backtrace).join("\n")
      "Error:\n#{indent(backtrace)}\n\n#{indent(color_message(message))}"
    end

    def indent(string, padding='    ')
      string.gsub(/^/, padding)
    end

    def color_message(string)
      "\e[31m#{string}\e[0m"
    end
  end

  class Failure
    def long_display
      backtrace = location.join("\n")
      "Failure:\n#{indent(backtrace)}\n\n#{indent(color_message(message))}"
    end

    def indent(string, padding='    ')
      string.gsub(/^/, padding)
    end

    def color_message(string)
      "\e[31m#{string}\e[0m"
    end
  end
end
