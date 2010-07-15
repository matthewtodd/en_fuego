ENV['RACK_ENV'] = 'test'
require 'test/unit'

require 'rubygems'
require 'bundler'
Bundler.require(:default, :test)

$:.unshift File.expand_path('../../lib',      __FILE__)
$:.unshift File.expand_path('../../test/lib', __FILE__)
require 'en_fuego'
require 'awesome_backtrace'

# Silence OpenID logging.
OpenID::Util.logger = Logger.new(nil)
