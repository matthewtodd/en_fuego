module EnFuego
  class Entry
    def self.from_json(feed)
      JSON.parse(feed).fetch('entries').map { |hash| new(hash) }
    end

    def initialize(attributes)
      @attributes = attributes

      @contents = []
      @contents.push(Workout.new(attributes['workout'])) if attributes['workout']
      @contents.push(Message.new(attributes['message'])) if attributes['message']
      @contents.push(Comments.new(attributes['comments'])) if attributes['comments']
    end

    def atom_id(uri)
      "#{uri}/#{@attributes['id']}"
    end

    def title
      ask_contents(:title, author_name) || "#{author_name} posted something"
    end

    def published
      @attributes['created_at']
    end

    def updated
      ask_contents(:updated_at) || @attributes['created_at']
    end

    def author_name
      @attributes['user']['display_name']
    end

    def author_url
      @attributes['user']['url']
    end

    def content
      @contents.map { |content| content.to_html }.join("\n\n")
    end

    def permalink
      @attributes['permalink']
    end

    private

    def ask_contents(*args)
      @contents.map { |content| content.send(*args) if content.respond_to?(args.first) }.flatten.first
    end
  end
end
