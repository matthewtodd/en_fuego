require 'test/helper'
require 'oauth/request_proxy/rack_request'

# mix in a little nicer 404 reporting
class EnFuego::Application
  not_found do
    raise ApplicationTest::UnimplementedRequest.new(request)
  end
end

class ApplicationTest < Test::Unit::TestCase
  def setup
    @application = EnFuego::Application.new
    @daily_mile  = ShamDailyMile.new
    ShamRack.mount(@application, 'en-fuego.com')
    ShamRack.mount(@daily_mile,  'api.dailymile.com')
    @daily_mile.register_oauth_consumer('http://en-fuego.com/sign-in')
  end

  def test_fetching_entries
    visit 'http://en-fuego.com/'
    click_button 'Sign In With DailyMile'
    click_button 'Allow'
    click_link 'Subscribe to Feed'
    should_see feed_for(entries)
  end

  private

  def visit(url)
    agent.get(url)
  end

  def click_button(text)
    form = current_page.forms.find { |form| form.button_with(:value => text) }
    flunk missing_element_message('button', text) if form.nil?
    form.click_button(form.button_with(:value => text))
  end

  def click_link(text)
    link = current_page.link_with(:text => text)
    flunk missing_element_message('link', text) if link.nil?
    link.click
  end

  def current_page
    @agent.current_page
  end

  def agent
    @agent ||= Mechanize.new
  end

  def missing_element_message(type, value)
    "Could not find #{type} with value \"#{value}\".\n#{current_page.uri}\n#{'-' * 80}\n#{current_page.body.rstrip}\n#{'-' * 80}"
  end

  class ShamDailyMile < Sinatra::Base
    not_found do
      raise UnimplementedRequest.new(request, :headers => true)
    end

    post '/oauth/request_token' do
      @provider.issue_request(request).query_string
    end

    get '/oauth/authorize' do
      erb <<-TEMPLATE
        <form method="post" action="<%= request.url %>">
          <input type="submit" value="Allow" />
        </form>
      TEMPLATE
    end

    post '/oauth/authorize' do
      user_request = @provider.backend.find_user_request(params[:oauth_token])
      user_request.authorize

      callback = user_request.callback.dup
      callback.query = "oauth_token=#{params[:oauth_token]}"
      redirect callback
    end

    post '/oauth/access_token' do
      @provider.upgrade_request(request).query_string
    end

    def initialize
      super
      @provider = OAuthProvider.create(:in_memory)
    end

    def register_oauth_consumer(callback)
      token = @provider.add_consumer(URI.parse(callback)).token
      ENV['OAUTH_TOKEN']        = token.shared_key
      ENV['OAUTH_TOKEN_SECRET'] = token.secret_key
    end
  end

  class UnimplementedRequest < RuntimeError
    def initialize(request, options={})
      @request = request
      super format_message(options)
    end

    def format_message(options)
      message = StringIO.new
      message.puts
      message.puts separator
      message.puts "#{method} to #{url}"
      message.puts separator

      if options.key?(:headers)
        headers.each do |key, value|
          message.puts "#{key}: #{value}"
        end
        message.puts separator
      end

      if options.key?(:body)
        message.puts body
        message.puts separator
      end

      message.string.rstrip
    end

    def method
      @request.env['REQUEST_METHOD']
    end

    def url
      @request.url
    end

    def separator
      '-' * 80
    end

    def headers
      @request.env.to_a.sort
    end

    def body
      @request.body.rewind
      @request.body.read
    end
  end

end
