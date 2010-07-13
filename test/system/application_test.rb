require 'test/helper'
require 'oauth/request_proxy/rack_request'

class ApplicationTest < Test::Unit::TestCase
  def setup
    ShamRack.mount(EnFuego::Application, 'en-fuego.com')
    ShamRack.mount(ShamDailyMile, 'api.dailymile.com')
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
    current_page.link_with(:text => text).click
  end

  def current_page
    @agent.current_page
  end

  def agent
    @agent ||= Mechanize.new
  end

  def missing_element_message(type, value)
    "Could not find #{type} with value \"#{value}\".\n#{'-' * 80}\n#{current_page.body}#{'-' * 80}"
  end

  class ShamDailyMile < Sinatra::Base
    not_found do
      raise("ShamDailyMile does not yet support #{env['REQUEST_METHOD']} #{request.url}")
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

    def initialize
      @provider = OAuthProvider.create(:in_memory)
    end
  end
end
