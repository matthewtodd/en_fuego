require 'test/helper'
require 'test/lib/formatted_error'
require 'test/lib/mechanize_driver'
require 'test/lib/sham_daily_mile'
require 'test/lib/sham_openid_provider'

class ApplicationTest < Test::Unit::TestCase
  include MechanizeDriver

  def test_fetching_entries
    visit 'http://en-fuego.com/'
    fill_in 'openid_url', :with => 'http://matthewtodd.org/'
    click_button 'Sign In With OpenID'
    click_button 'Authorize'
    click_button 'Allow'
    click_link 'Subscribe to Feed'
    should_see feed_for(entries)
  end

  def setup
    daily_mile = ShamDailyMile.new
    daily_mile.register_oauth_consumer('http://en-fuego.com/sign-up')

    openid_provider = ShamOpenIDProvider.new('http://matthewtodd.org/')

    ShamRack.mount(openid_provider,      'matthewtodd.org')
    ShamRack.mount(daily_mile,           'api.dailymile.com')
    ShamRack.mount(EnFuego::Application, 'en-fuego.com')
  end

  def teardown
    ShamRack.unmount_all
  end
end

# This makes for more understandable test failures:
class EnFuego::Application
  not_found do
    raise UnimplementedRequest.new(request)
  end
end
