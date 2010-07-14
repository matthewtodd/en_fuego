module MechanizeDriver
  def agent
    @agent ||= Mechanize.new
  end

  def click_button(text)
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

  def visit(url)
    agent.get(url)
  end
end
