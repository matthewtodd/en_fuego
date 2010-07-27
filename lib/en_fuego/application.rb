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

      def post_entry(consumer, attributes)
        access_token(consumer).post('/entries.json', attributes.to_json, 'Accept' => 'application/json', 'Content-Type' => 'application/json')
      end

      private

      def access_token(consumer)
        OAuth::AccessToken.new(consumer, oauth_token, oauth_token_secret)
      end
    end

    # TODO would something like OpenStruct give me easier method-like access to attributes?
    class Entry
      def self.from_json(feed)
        JSON.parse(feed).fetch('entries').map { |hash| new(hash) }
      end

      def initialize(attributes)
        @attributes = attributes
      end

      def updated
        @attributes['created_at']
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

          xml.content content, :type => 'html'
          xml.link :rel => 'self', :href => permalink
          xml.published updated
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
        content = []
        content.push(workout_html) if @attributes['workout']
        content.push(media_html)   if @attributes['media']
        content.push(message_html) if @attributes['message']
        content.join("\n\n")
      end

      def permalink
        @attributes['permalink']
      end

      def workout_html
        "<pre>#{JSON.pretty_generate(@attributes['workout'])}</pre>"
      end

      def media_html
        ''
      end

      def message_html
        "<p>#{@attributes['message']}</p>"
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
        # TODO squash these 2 lines together.
        user = User.create(attributes)
        session.user = user
        redirect '/'
      end
    end

    # TODO change this path to mirror DailyMile, thus leaving the namespace more open to additions.
    # But wait to change it until I've heard back from Socialite support!
    get '/feed/:api_key' do
      # TODO see if there's a way to raise a not found from sequel, and then catch that with sinatra.
      user = User[:api_key => params[:api_key]]
      not_found unless user
      @entries = user.fetch_entries(oauth_consumer)

      content_type :atom
      builder :feed
    end

    # TODO don't just render sign_in; redirect instead.
    # TODO move authentication logic to a before filter?
    post '/entries' do
      if session.user
        session.user.post_entry(oauth_consumer, params[:entry])
        redirect '/'
      else
        erb :sign_in
      end
    end
  end
end
