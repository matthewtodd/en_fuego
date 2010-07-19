module EnFuego
  class Application < Sinatra::Base
    set :views, EnFuego.datadir('views')

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
        string :identity_url,       :null => false, :unique => true
        string :api_key,            :null => false, :unique => true
        string :oauth_token,        :null => false
        string :oauth_token_secret, :null => false
      end
    end

    class User < Sequel::Model
      def before_create
        self.api_key =
          Digest::SHA1.hexdigest("#{rand}-#{Time.now}-#{rand}")
        super
      end

      def fetch_entries(consumer)
        access_token(consumer).get('/entries/friends.json').body
      end

      private

      def access_token(consumer)
        OAuth::AccessToken.new(consumer, oauth_token, oauth_token_secret)
      end
    end

    get '/' do
      if session.user
        erb :dashboard
      else
        erb :sign_in
      end
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
        user = User.create(attributes)
        session.user = user
        redirect '/'
      end
    end

    get '/feed/:api_key' do
      user = User[:api_key => params[:api_key]]
      not_found unless user

      user.fetch_entries(oauth_consumer)
      #builder do |xml|
        #xml.foo do
          #user.fetch_entries(oauth_consumer).each do |entry|
            #xml.title entry.title
          #end
        #end
      #end
    end
  end
end
