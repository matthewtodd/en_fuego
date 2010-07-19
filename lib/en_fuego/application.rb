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
        String :identity_url,       :null => false, :unique => true
        String :api_key,            :null => false, :unique => true
        String :oauth_token,        :null => false
        String :oauth_token_secret, :null => false
      end
    end

    class User < Sequel::Model
      def before_create
        self.api_key =
          Digest::SHA1.hexdigest("#{rand}-#{Time.now}-#{rand}")
        super
      end

      def fetch_entries(consumer)
        raw_json = access_token(consumer).get('/entries/friends.json').body
        Entry.from_json(raw_json)
      end

      private

      def access_token(consumer)
        OAuth::AccessToken.new(consumer, oauth_token, oauth_token_secret)
      end
    end

    class Entry
      def self.from_json(feed)
        JSON.parse(feed).fetch('entries').map { |hash| new(hash) }
      end

      def initialize(attributes)
        @attributes = attributes
      end

      def updated
        Time.parse(@attributes['created_at']).utc.strftime('%Y-%m-%dT%H:%M:%SZ')
      end

      def to_xml(xml, uri)
        xml.entry do
          xml.id atom_id(uri)
          xml.title title
          xml.updated updated

          xml.author do
            xml.name user_name
            xml.uri  user_url
          end

          xml.content content
          xml.link :rel => 'alternate', :href => permalink
        end
      end

      private

      def atom_id(uri)
        "#{uri}/#{@attributes['id']}"
      end

      def title
        "#{user_name} posted a workout"
      end

      def user_name
        @attributes['user']['display_name']
      end

      def user_url
        @attributes['user']['url']
      end

      def content
        [@attributes['workout'].inspect, @attributes['message']].join("\n\n")
      end

      def permalink
        @attributes['permalink']
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
      entries = user.fetch_entries(oauth_consumer)

      content_type 'application/atom+xml'

      builder do |xml|
        xml.instruct!
        xml.feed(:xmlns => 'http://www.w3.org/2005/Atom') do
          xml.id request.url
          xml.title 'En Fuego'
          xml.updated entries.first.updated
          xml.link :rel => 'self', :href => request.url

          entries.each do |entry|
            entry.to_xml(xml, request.url)
          end
        end
      end
    end
  end
end
