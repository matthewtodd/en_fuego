require 'rubygems'
require 'bundler'
Bundler.require(:default)

$:.unshift File.expand_path('../lib', __FILE__)
require 'en_fuego'

# Fake Heroku environment variables.
if ENV['RACK_ENV'] == 'development'
  if File.exist?(path = 'config/environment.yml')
    YAML.load_file(path).each do |key, value|
      ENV[key.upcase] = value
    end
  end
end

run EnFuego::Application
