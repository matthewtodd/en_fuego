module MechanizeDriver
  def agent
    @agent ||= Mechanize.new
  end

  def choose(name, value)
    criteria = { :name => name, :value => value }
    form = current_page.forms.find { |form| form.radiobutton_with(criteria) }
    raise MissingElement.new('radio button', criteria.inspect, current_page) if form.nil?
    form.radiobutton_with(criteria).check
  end

  def click_button(text)
    raise MissingElement.new('button', text, current_page) unless current_page.kind_of?(Mechanize::Page)
    form = current_page.forms.find { |form| form.button_with(:value => text) }
    raise MissingElement.new('button', text, current_page) if form.nil?
    form.click_button(form.button_with(:value => text))
  end

  def click_link(text)
    link = current_page.link_with(:text => text)
    raise MissingElement.new('link', text, current_page) if link.nil?
    link.click
  end

  def current_page
    @agent.current_page.extend(PageExtensions)
  end

  def fill_in(name, options={})
    form = current_page.forms.find { |form| form.has_field?(name) }
    raise MissingElement.new('field', name, current_page) if form.nil?
    form[name] = options[:with]
  end

  def follow_header_link(options)
    link = current_page.header_link_with(options)
    raise MissingElement.new('header link', options.inspect, current_page) if link.nil?
    link.click
  end

  def should_see_xpath(expression)
    dom = Nokogiri::XML(current_page.content)
    if dom.search(expression).empty?
      raise MissingXpath.new(expression, current_page)
    end
  end

  def visit(url)
    agent.get(url)
  end

  module PageExtensions
    def header_links
      search('head > link').map do |node|
        Mechanize::Page::Link.new(node, @mech, self)
      end
    end

    def header_link_with(attributes)
      header_links.find do |link|
        attributes.all? { |key, value| link.attributes[key] == value }
      end
    end
  end
end
