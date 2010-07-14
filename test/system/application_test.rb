require 'test/helper'
require 'test/lib/formatted_error'
require 'test/lib/mechanize_driver'
require 'test/lib/sham_daily_mile'

class ApplicationTest < Test::Unit::TestCase
  include MechanizeDriver

  def test_fetching_entries
    visit 'http://en-fuego.com/'
    click_button 'Sign In With DailyMile'
    click_button 'Allow'
    click_link 'Subscribe to Feed'
    should_see feed_for(entries)
  end

  def setup
    daily_mile = ShamDailyMile.new
    daily_mile.register_oauth_consumer('http://en-fuego.com/sign-in')
    ShamRack.mount(daily_mile,           'api.dailymile.com')
    ShamRack.mount(EnFuego::Application, 'en-fuego.com')
  end

  def teardown
    ShamRack.unmount_all
  end
end
