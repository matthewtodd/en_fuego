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

      def atom_id(uri)
        "#{uri}/#{@attributes['id']}"
      end

      def title
        "#{author_name} posted a workout"
      end

      def updated
        @attributes['created_at']
      end

      def author_name
        @attributes['user']['display_name']
      end

      def author_url
        @attributes['user']['url']
      end

      def content
        content = []
        content.push(workout_html) if @attributes['workout']
        content.push(media_html)   if @attributes['media']
        content.push(message_html) if @attributes['message']
        content.push('<hr />')
        content.push(attributes_html)
        content.join("\n\n")
      end

      def permalink
        @attributes['permalink']
      end

      private

      def workout_html
        Workout.new(@attributes['workout']).to_html
      end

      def media_html
        Media.new(@attributes['media']).to_html
      end

      def message_html
        "<p>#{@attributes['message']}</p>"
      end

      def attributes_html
        "<pre>#{JSON.pretty_generate(@attributes)}</pre>"
      end
    end

    class Workout
      def initialize(attributes)
        @title    = attributes['title']
        @duration = Duration.new(attributes['duration'])
        @type     = attributes['type']
        @felt     = attributes['felt']
        @distance = Distance.new(attributes['distance'] || {})
      end

      def to_html
        if @type == 'running'
          content = []
          content.push "<h1>#{@title}</h1>" if @title
          content.push "<p>Ran #{@distance} in #{@duration} and felt #{@felt}.</p>"
          content.join("\n\n")
        else
          ''
        end
      end
    end

    class Media
      def initialize(attributes)
      end

      def to_html
        ''
      end
    end

    class Duration
      def initialize(value)
        @value = value
      end

      def to_s
        if @value
          minutes, seconds = @value.to_i.divmod(60)
          "#{minutes}:#{seconds}"
        else
          'unknown time'
        end
      end
    end

    class Distance
      def initialize(attributes)
        @value = attributes['value']
        @units = attributes['units']
      end

      def to_s
        if @value
          "#{@value} #{@units}"
        else
          'unknown distance'
        end
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
