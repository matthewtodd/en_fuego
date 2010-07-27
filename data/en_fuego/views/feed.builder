xml.instruct!
xml.feed(:xmlns => 'http://www.w3.org/2005/Atom') do
  xml.id request.url
  xml.title 'En Fuego'
  xml.updated @entries.first.updated
  xml.link :rel => 'self',      :href => request.url
  xml.link :rel => 'alternate', :href => request.url[0...request.url.index(request.fullpath)]

  @entries.each do |entry|
    entry.to_xml(xml, request.url)
  end
end
