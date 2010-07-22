require 'rubygems'
require 'bundler'
Bundler.require(:default)

$:.unshift File.expand_path('../lib', __FILE__)
require 'en_fuego'

application = EnFuego::Application.new do |app|
  app.options.oauth_consumer = OAuth::Consumer.new(
    ENV['OAUTH_TOKEN'],
    ENV['OAUTH_SECRET'],
    :site => ENV['OAUTH_SITE']
  )
end

run application
