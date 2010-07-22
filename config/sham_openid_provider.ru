require 'rubygems'
require 'bundler'
Bundler.require(:default)

$:.unshift File.expand_path('../../test/lib', __FILE__)
require 'formatted_error'
require 'sham_openid_provider'

# Make logging blue.
def $stderr.write(message)
  super "\e[34m#{message}\e[0m"
end

run ShamOpenIDProvider.new('http://localhost:9293/')
