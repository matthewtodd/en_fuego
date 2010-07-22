require 'rake/testtask'

Rake::TestTask.new do |task|
  task.pattern = 'test/**/*_test.rb'
end

task :default => :test

desc 'Start development servers'
task :development do
  require 'rack'

  ENV['OAUTH_TOKEN']    = 'bxq1CNkdzu6vdwWM7NrDw'
  ENV['OAUTH_SECRET']   = '9kaeGkfUjEPG0qWD0Egu08bZh80hsEo1UiEpPFX9Cw'
  ENV['OAUTH_SITE']     = 'http://localhost:9294'
  ENV['SESSION_SECRET'] = '79245b67cfe6a53f16d37608249c7a846ce502a90238be669654bbbd7cd565c9ca97cc0a2fd9d98d45cd61abb054a58e7cb06250cbb04451fa33b9147957caa8'

  pids = %w(
    config.ru
    config/sham_openid_provider.ru
    config/sham_daily_mile.ru
  ).enum_for(:map).with_index do |path, index|
    fork do
      Rack::Server.start(:config => path, :Port => (9292 + index))
    end
  end

  trap(:INT) { Process.kill(:INT, *pids) }
  Process.waitall
end
