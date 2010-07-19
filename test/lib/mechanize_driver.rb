module MechanizeDriver
  def agent
    @agent ||= Mechanize.new
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
    @agent.current_page
  end

  def fill_in(name, options={})
    form = current_page.forms.find { |form| form.text_field?(name) }
    raise MissingElement.new('text field', name, current_page) if form.nil?
    form[name] = options[:with]
  end

  def should_see(text)
    unless current_page.body.include?(text)
      raise MissingText.new(text, current_page)
    end
  end

  def visit(url)
    agent.get(url)
  end
end
