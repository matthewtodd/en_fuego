module EnFuego
  class Application < Sinatra::Base
    set :views, EnFuego.datadir('views')

    use Rack::Session::Cookie,
      :expire_after => 31_536_000, # 1 year
      :secret       => ENV['SESSION_SECRET']

    register Extensions::OAuth
    register Extensions::OpenID
    register Extensions::Session

    get '/' do
      if session.user
        erb :dashboard
      else
        erb :sign_in
      end
    end

    post '/sign-in' do
      authenticate_with_openid do |identity_url|
        if user = User.find_by_identity_url(identity_url)
          session.user = user
          redirect '/'
        else
          start_authorize_with_oauth(:identity_url => identity_url)
        end
      end
    end

    get '/sign-up' do
      finish_authorize_with_oauth do |attributes|
        user = User.create(attributes)
        session.user = user
        redirect '/'
      end
    end
  end
end
