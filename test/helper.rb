ENV['RACK_ENV'] = 'test'
require 'test/unit'

require 'rubygems'
require 'bundler'
Bundler.require(:default, ENV['RACK_ENV'])
$:.unshift File.expand_path('../../lib', __FILE__)
require 'en_fuego'


# These tweaks make backtraces WAY easier to read!
module Test::Unit
  module Util::BacktraceFilter
    ROOT = File.expand_path('../..', __FILE__)

    def filter_backtrace(backtrace, prefix=nil)
      backtrace.collect { |line| line.sub(ROOT, '.') }.
                select  { |line| line.start_with?('.') }.
                reject  { |line| line.include?('vendor') }.
                collect { |line| "%s\tline %s\t%s" % line.split(':') }.
                collect { |line| color(line) }.
                reverse
    end

    def color(line)
      if line.start_with?('./lib')
        "\e[44m#{line}\e[0m"
      else
        "\e[0m#{line}\e[0m"
      end
    end
  end

  class Error
    def long_display
      backtrace = filter_backtrace(@exception.backtrace).join("\n")
      "Error:\n#{indent(backtrace)}\n\n#{indent(red(message))}"
    end

    def indent(string, padding='    ')
      string.gsub(/^/, padding)
    end

    def red(string)
      "\e[31m#{string}\e[0m"
    end
  end

  class Failure
    def long_display
      backtrace = location.join("\n")
      "Failure:\n#{indent(backtrace)}\n\n#{indent(red(message))}"
    end

    def indent(string, padding='    ')
      string.gsub(/^/, padding)
    end

    def red(string)
      "\e[31m#{string}\e[0m"
    end
  end
end
