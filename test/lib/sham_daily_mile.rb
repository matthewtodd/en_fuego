require 'oauth/request_proxy/rack_request'

class ShamDailyMile < Sinatra::Base
  post '/oauth/request_token' do
    provider.issue_request(request).query_string
  end

  get '/oauth/authorize' do
    erb <<-TEMPLATE
      <form method="post" action="<%= request.url %>">
        <input type="submit" value="Allow" />
      </form>
    TEMPLATE
  end

  post '/oauth/authorize' do
    redirect provider.authorize_request(params[:oauth_token]).callback
  end

  post '/oauth/access_token' do
    provider.upgrade_request(request).query_string
  end

  not_found do
    raise UnimplementedRequest.new(request, :headers => true)
  end

  def register_oauth_consumer(callback)
    token = provider.add_consumer(callback).token
    ENV['OAUTH_TOKEN']  = token.shared_key
    ENV['OAUTH_SECRET'] = token.secret_key
  end

  private

  def provider
    @provider ||= OAuthProvider.create(:in_memory).extend(OAuthProviderExtensions)
  end

  module OAuthProviderExtensions
    def authorize_request(token)
      request = @backend.find_user_request(token)
      request.authorize
      request.extend(OAuthUserRequestExtensions)
    end
  end

  module OAuthUserRequestExtensions
    def callback
      "#{super}?oauth_token=#{shared_key}"
    end
  end
end
