xml.instruct!

xml.feed(:xmlns => 'http://www.w3.org/2005/Atom') do
  xml.id request.url
  xml.title 'En Fuego'
  xml.updated @entries.first.updated
  xml.link :rel => 'self',      :href => request.url
  xml.link :rel => 'alternate', :href => request.url[0...request.url.index(request.fullpath)]

  @entries.each do |entry|
    xml.entry do
      xml.id      entry.atom_id(request.url)
      xml.title   entry.title
      xml.updated entry.updated

      xml.author do
        xml.name entry.author_name
        xml.uri  entry.author_url
      end

      xml.content   entry.content, :type => 'html'
      xml.link      :href => entry.permalink, :rel => 'self'
      xml.published entry.published
    end
  end
end
