require 'rubygems'
require 'bundler'
Bundler.require(:default)

$:.unshift File.expand_path('../../test/lib', __FILE__)
require 'formatted_error'
require 'sham_daily_mile'

# Make logging green.
def $stderr.write(message)
  super "\e[32m#{message}\e[0m"
end

oauth_consumer = OAuth::Consumer.new(
  ENV['OAUTH_TOKEN'],
  ENV['OAUTH_SECRET'],
  :site => ENV['OAUTH_SITE']
)

run ShamDailyMile.new(oauth_consumer, 'http://localhost:9292/sign-up')
