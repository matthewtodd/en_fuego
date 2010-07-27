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

        @contents = []
        @contents.push(Workout.new(attributes['workout'])) if attributes['workout']
        @contents.push(Message.new(attributes['message'])) if attributes['message']
        @contents.push(Comments.new(attributes['comments'])) if attributes['comments']
        @contents.push(Attributes.new(attributes))
      end

      def atom_id(uri)
        "#{uri}/#{@attributes['id']}"
      end

      def title
        ask_contents(:title, author_name) || "#{author_name} posted something"
      end

      def published
        @attributes['created_at']
      end

      def updated
        ask_contents(:updated_at) || @attributes['created_at']
      end

      def author_name
        @attributes['user']['display_name']
      end

      def author_url
        @attributes['user']['url']
      end

      def content
        @contents.map { |content| content.to_html }.join("\n\n")
      end

      def permalink
        @attributes['permalink']
      end

      private

      def ask_contents(*args)
        @contents.map { |content| content.send(*args) if content.respond_to?(args.first) }.flatten.first
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

      def title(author_name)
        case @type
        when 'running'
          "#{author_name} ran #{@distance}"
        when 'cycling'
          "#{author_name} cycled #{@distance}"
        when 'swimming'
          "#{author_name} swam #{@distance}"
        when 'walking'
          "#{author_name} walked #{@distance}"
        when 'fitness'
          "#{author_name} worked out"
        end
      end

      def to_html
        content = []
        content.push "<h1>#{@title}</h1>" if @title

        case @type
        when 'running'
          content.push "<p>Ran #{@distance} in #{@duration} and felt #{@felt}.</p>"
        when 'cycling'
          content.push "<p>Cycled #{@distance} in #{@duration} and felt #{@felt}.</p>"
        when 'swimming'
          content.push "<p>Swam #{@distance} in #{@duration} and felt #{@felt}.</p>"
        when 'walking'
          content.push "<p>Walked #{@distance} in #{@duration} and felt #{@felt}.</p>"
        when 'fitness'
          content.push "<p>Worked out and felt #{@felt}.</p>"
        end

        content.join("\n\n")
      end
    end

    class Duration
      def initialize(value)
        @value = value
      end

      def to_s
        if @value
          '%d:%02d' % @value.to_i.divmod(60)
        else
          'an unknown time'
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
          'an unknown distance'
        end
      end
    end

    class Message
      def initialize(message)
        @message = message
      end

      def to_html
        "<p>#{@message}</p>"
      end
    end

    class Comments
      def initialize(comments)
        @comments = comments
      end

      def updated_at
        @comments.map { |comment| comment['created_at'] }.max
      end

      def to_html
        "<h2>Comments</h2><ol>#{@comments.map { |c| comment_html(c) }}</ol>"
      end

      private

      def comment_html(comment)
        "<li><p>#{comment['user']['display_name']}: #{comment['body']}</p></li>"
      end
    end

    class Attributes
      def initialize(attributes)
        @attributes = attributes
      end

      def to_html
        "<pre>#{JSON.pretty_generate(@attributes)}</pre>"
        ''
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
