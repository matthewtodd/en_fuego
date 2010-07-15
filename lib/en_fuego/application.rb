module EnFuego
  class Application < Sinatra::Base
    set :views, EnFuego.datadir('views')

    use RackEnvironment if development?
    use Rack::Session::Cookie
    use Rack::OpenID

    get '/' do
      if session_user
        "You Made It!"
      else
        redirect '/sign-in'
      end
    end

    get '/sign-in' do
      erb :sign_in
    end

    post '/sign-in' do
      if response = request.env[Rack::OpenID::RESPONSE]
        case response.status
        when :success
          if user = User.find_by_identity_url(response.identity_url)
            session_user(user)
            redirect '/'
          else
            token = oauth_consumer.get_request_token
            session_identity_url(response.identity_url)
            session_request_token(token)
            redirect token.authorize_url
          end
        else
          halt response.inspect
        end
      else
        headers Rack::OpenID::AUTHENTICATE_HEADER =>
          Rack::OpenID.build_header(:identifier => params['openid_url'])
        halt [401, 'You are being redirected.']
      end
    end

    get '/sign-up' do
      oauth_token    = params[:oauth_token]
      oauth_verifier = params[:oauth_verifier]

      request_token = session_request_token # TODO check match
      access_token  = request_token.get_access_token(:oauth_verifier => oauth_verifier)

      user = User.create(
               :identity_url => session_identity_url,
               :access_token => access_token)
      session_user(user)
      redirect '/'
    end

    helpers do
      def oauth_consumer
        OAuth::Consumer.new(ENV['OAUTH_TOKEN'], ENV['OAUTH_SECRET'], :site => 'http://api.dailymile.com')
      end

      def session_user(user=nil)
        if user
          session[:user] = user.identity_url
        else
          User.find_by_identity_url(session[:user])
        end
      end

      def session_identity_url(url=nil)
        if url
          session[:identity_url] = url
        else
          session[:identity_url]
        end
      end

      def session_request_token(token=nil)
        if token
          session[:oauth_token]  = token.token
          session[:oauth_secret] = token.secret
        else
          OAuth::RequestToken.new(oauth_consumer, session[:oauth_token], session[:oauth_secret])
        end
      end
    end
  end
end
