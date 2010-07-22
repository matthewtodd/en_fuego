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

  def test_posting_an_entry
    visit 'http://en-fuego.com/'
    fill_in 'openid_url', :with => 'matthewtodd.org'
    click_button 'Sign In With OpenID'
    click_button 'Authorize'
    click_button 'Allow'

    fill_in 'entry[message]', :with => 'Excellent run today!'
    fill_in 'entry[workout][activity_type]', :with => 'running'
    fill_in 'entry[workout][completed_at]', :with => '2010-07-22'
    fill_in 'entry[workout][distance][value]', :with => '10'
    fill_in 'entry[workout][distance][units]', :with => 'miles'
    fill_in 'entry[workout][duration]', :with => '6000'
    fill_in 'entry[workout][felt]', :with => 'good'
    fill_in 'entry[workout][title]', :with => 'Lema Rd. / Coffee Fields'
    click_button 'Post Entry'

    click_link 'Subscribe to Feed'
    should_see_entry :message => 'Excellent run today!'
  end

  protected

  def setup
    ShamRack.mount(ShamDailyMile.new('http://en-fuego.com/sign-up'),  'api.dailymile.com')
    ShamRack.mount(ShamOpenIDProvider.new('http://matthewtodd.org/'), 'matthewtodd.org')
    ShamRack.mount(EnFuego::Application, 'en-fuego.com')

    # start with a clean database
    ShamRack.application_for('en-fuego.com').database[:users].truncate
  end

  def teardown
    ShamRack.unmount_all
  end

  private

  def should_see_each_entry
    ShamRack.application_for('api.dailymile.com').entries.each do |entry|
      should_see_entry(entry)
    end
  end

  def should_see_entry(entry)
    should_see_xpath "/xmlns:feed/xmlns:entry/xmlns:content[contains(text(), '#{entry[:message]}')]"
  end
end

# This makes for more understandable test failures:
class EnFuego::Application
  not_found do
    raise UnimplementedRequest.new(request)
  end
end
