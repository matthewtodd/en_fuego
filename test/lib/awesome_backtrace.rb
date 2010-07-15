# These tweaks make backtraces WAY easier to read!
module Test::Unit
  module Util::BacktraceFilter
    ROOT = File.expand_path('../../..', __FILE__)

    def filter_backtrace(backtrace, prefix=nil)
      #return backtrace.reverse # useful if something goes wonky

      backtrace.collect { |line| line.sub(ROOT, '.') }.
                collect { |line| replace_ruby_path(line) }.
                collect { |line| replace_gem_path(line) }.
                reject  { |line| line.start_with?('RUBY') }.
                reject  { |line| line.start_with?('GEM') }.
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

      filename_width = 44
      line_width     = 4

      format = "%-#{filename_width}.#{filename_width}s line %-#{line_width}.#{line_width}s"
      format << ' %s' if parts.length > 2
      format % parts
    end

    def replace_ruby_path(line)
      line.sub("#{RbConfig::CONFIG['rubylibdir']}/", 'RUBY ')
    end

    def replace_gem_path(line)
      Gem.path.each do |path|
        line.sub! "#{path}/gems/", 'GEM '
      end

      line
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
