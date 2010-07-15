require 'oauth/request_proxy/rack_request'

class ShamDailyMile < Sinatra::Base
  post '/oauth/request_token' do
    @tokens.issue_request(request)
  end

  get '/oauth/authorize' do
    erb <<-TEMPLATE
      <form method="post" action="<%= request.url %>">
        <input type="submit" value="Allow" />
      </form>
    TEMPLATE
  end

  post '/oauth/authorize' do
    redirect @tokens.authorize!
  end

  post '/oauth/access_token' do
    @tokens.upgrade_request(request)
  end

  not_found do
    raise UnimplementedRequest.new(request, :headers => true)
  end

  def initialize(callback)
    @tokens = Tokens.new(callback)
    @tokens.populate(ENV)
    super(nil)
  end

  class Tokens
    include OAuth::Helper

    def initialize(callback)
      @consumer   = OAuth::ServerToken.new
      @request    = OAuth::ServerToken.new
      @access     = OAuth::ServerToken.new
      @authorized = false
      @callback   = "#{callback}?oauth_token=#{@request.token}"
    end

    def populate(hash)
      ENV['OAUTH_TOKEN']  = @consumer.token
      ENV['OAUTH_SECRET'] = @consumer.secret
    end

    def issue_request(request)
      verify(request)
      query_string(@request)
    end

    def authorize!
      @authorized = true
      @callback
    end

    def upgrade_request(request)
      verify(request, :token => @request)
      raise "Token not authorized." unless @authorized
      query_string(@access)
    end

    private

    # I'd like to just say token.to_query, but it puts the secret in
    # "oauth_secret", while OAuth::ConsumerToken.from_hash looks for it in
    # "oauth_token_secret".
    def query_string(token)
      "oauth_token=#{escape(token.token)}&oauth_token_secret=#{escape(token.secret)}"
    end

    def verify(request, options={})
      sig = OAuth::Signature.build(request, options.merge(:consumer => @consumer))
      unless sig.verify
        raise "Signature verification failed: #{sig.signature} != #{sig.request.signature}"
      end
    end
  end
end
