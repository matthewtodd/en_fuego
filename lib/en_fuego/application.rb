module EnFuego
  class Application < Sinatra::Base
    use Warden::Manager do |config|
      config.strategies.add :oauth, EnFuego::Authentication::OAuth
      config.default_strategies :oauth
      config.failure_app = EnFuego::Application
      config.serialize_into_session { |user| user.oauth_token }
      config.serialize_from_session { |oauth_token| User.find_by_oauth_token(oauth_token) }
    end

    set :sessions, true
    set :views, EnFuego.datadir('views')

    get '/' do
      env['warden'].authenticate!
      'Hello World!'
    end

    get '/unauthenticated' do
      erb :unauthenticated
    end
  end
end
