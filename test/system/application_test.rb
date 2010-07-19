require 'test/helper'
require 'formatted_error'
require 'mechanize_driver'
require 'sham_daily_mile'
require 'sham_openid_provider'

class ApplicationTest < Test::Unit::TestCase
  include MechanizeDriver

  def test_fetching_entries
    visit 'http://en-fuego.com/'
    fill_in 'openid_url', :with => 'matthewtodd.org'
    click_button 'Sign In With OpenID'
    click_button 'Authorize'
    click_button 'Allow'
    click_link 'Subscribe to Feed'
    should_see_each_entry
  end

  protected

  def setup
    @daily_mile      = ShamDailyMile.new('http://en-fuego.com/sign-up')
    @openid_provider = ShamOpenIDProvider.new('http://matthewtodd.org/')

    ShamRack.mount(@daily_mile,          'api.dailymile.com')
    ShamRack.mount(@openid_provider,     'matthewtodd.org')
    ShamRack.mount(EnFuego::Application, 'en-fuego.com')
  end

  def teardown
    ShamRack.unmount_all
  end

  private

  def should_see_each_entry
    @daily_mile.entries.each do |entry|
      should_see(entry[:message].succ)
    end
  end
end

# This makes for more understandable test failures:
class EnFuego::Application
  not_found do
    raise UnimplementedRequest.new(request)
  end
end
