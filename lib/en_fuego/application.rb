module EnFuego
  class Application < Sinatra::Base
    use RackEnvironment if development?
    use Rack::Session::Cookie
    use Rack::OpenID

    set :views, EnFuego.datadir('views')

    get '/' do
      erb(session.user ? :dashboard : :sign_in)
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

    def authenticate_with_openid
      if response = request.env[Rack::OpenID::RESPONSE]
        case response.status
        when :success
          yield response.identity_url
        end
      else
        headers Rack::OpenID::AUTHENTICATE_HEADER =>
          Rack::OpenID.build_header(:identifier => params['openid_url'])
        halt [401, 'You are being redirected.']
      end
    end

    def start_authorize_with_oauth(user_attributes)
      request_token = oauth_consumer.get_request_token

      session.request_token   = request_token
      session.user_attributes = user_attributes

      redirect request_token.authorize_url
    end

    def finish_authorize_with_oauth
      oauth_token    = params[:oauth_token]
      oauth_verifier = params[:oauth_verifier]
      request_token  = session.request_token(oauth_consumer, oauth_token)
      access_token   = request_token.get_access_token(:oauth_verifier => oauth_verifier)

      yield session.user_attributes.merge(:access_token => access_token)

      session.request_token   = nil
      session.user_attributes = nil
    end

    def oauth_consumer
      OAuth::Consumer.new(ENV['OAUTH_TOKEN'], ENV['OAUTH_SECRET'], :site => 'http://api.dailymile.com')
    end

    def session
      super.extend(Session)
    end
  end
end
