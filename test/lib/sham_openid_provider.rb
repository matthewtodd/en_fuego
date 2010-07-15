require 'openid/store/memory'

class ShamOpenIDProvider < Sinatra::Base
  set :sessions, true

  get '/' do
    erb <<-TEMPLATE
      <!doctype html>
      <html>
        <head>
          <link rel="openid.server" href="<%= @server.op_endpoint %>" />
        </head>
        <body>
          <h1>This is an OpenID server.</h1>
        </body>
      </html>
    TEMPLATE
  end

  get '/openid' do
    # TODO should also handle a checkid_immediate request
    session[:openid_request] = @server.decode_request(params)
    redirect '/openid/decide'
  end

  post '/openid' do
    openid_request  = @server.decode_request(params)
    openid_response = @server.handle_request(openid_request)
    halt @server.encode_response(openid_response)
  end

  get '/openid/decide' do
    <<-HTML
      <form method="post">
        <input type="Submit" name="decision" value="Authorize" />
      </form>
    HTML
  end

  # TODO should handle a "NO" choice as well.
  post '/openid/decide' do
    openid_request  = session.delete(:openid_request)
    openid_response = openid_request.answer(true, nil, openid_request.identity)
    halt @server.encode_response(openid_response)
  end

  not_found do
    error = UnimplementedRequest.new(request, :headers => true)
    # If we raise here, the OpenID library will just wrap our exception, which
    # Rack::OpenID will then swallow and mask it with an information-less
    # MissingResponse. So, we puts.
    puts "\e[31m#{error.class}:#{error.message}\e[0m".gsub(/^/, '    ')
  end

  def initialize(root)
    store    = OpenID::Store::Memory.new
    endpoint = root.chomp('/').concat('/openid')
    @server  = OpenID::Server::Server.new(store, endpoint)
    @server.extend(ServerExtensions)

    super(nil)
  end

  module ServerExtensions
    def encode_response(*args)
      super.extend(WebResponseExtensions)
    end
  end

  module WebResponseExtensions
    def to_ary
      [code, headers, body]
    end
  end
end
