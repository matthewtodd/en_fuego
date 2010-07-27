module EnFuego
  class Application < Sinatra::Base
    set :views, EnFuego.datadir('views')

    use Rack::Deflater
    use Rack::Session::Cookie,
      :expire_after => 31_536_000, # 1 year
      :secret       => ENV['SESSION_SECRET']

    register Extensions::OAuth
    register Extensions::OpenID
    register Extensions::Sequel
    register Extensions::Session

    migration 'create users' do |database|
      database.create_table :users do
        primary_key :id
        String :identity_url,       :null => false, :unique => true
        String :api_key,            :null => false, :unique => true
        String :oauth_token,        :null => false
        String :oauth_token_secret, :null => false
      end
    end

    get '/' do
      if session.user
        erb :dashboard
      else
        redirect '/sign-in'
      end
    end

    post '/entries' do
      if session.user
        session.user.post_entry(oauth_consumer, params[:entry])
        redirect '/'
      else
        redirect '/sign-in'
      end
    end

    get '/:api_key/entries/friends.atom' do
      if user = User[:api_key => params[:api_key]]
        content_type :atom
        builder :feed, :locals => { :entries => user.fetch_entries(oauth_consumer) }
      else
        not_found
      end
    end

    get '/sign-in' do
      erb :sign_in
    end

    post '/sign-in' do
      authenticate_with_openid do |identity_url|
        if user = User[:identity_url => identity_url]
          session.user = user
          redirect '/'
        else
          start_authorize_with_oauth(:identity_url => identity_url)
        end
      end
    end

    get '/sign-up' do
      finish_authorize_with_oauth do |attributes|
        session.user = User.create(attributes)
        redirect '/'
      end
    end
  end
end
