source 'http://rubygems.org/'

gem 'builder',        '~> 2.1.2'
gem 'json_pure',      '~> 1.4.3', :require => 'json'
gem 'oauth',          '~> 0.4.1'
gem 'rack-openid',    '~> 1.0.3', :require => 'rack/openid'
gem 'sequel',         '~> 3.13.0'
gem 'sinatra',        '=  1.0'

group :development do
  gem 'heroku',       '~> 1.9.10'
end

group :development, :test do
  gem 'sqlite3-ruby', '~> 1.2.5', :require => 'sqlite3'
end

group :test do
  gem 'mechanize',    '~> 1.0.0'
  gem 'redgreen',     '~> 1.2.2'
  gem 'sham_rack',    '~> 1.3.1'
end

group :production do
  gem 'pg',             '~> 0.9.0'
end
