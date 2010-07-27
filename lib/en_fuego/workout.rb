module EnFuego
  class Workout
    def initialize(attributes)
      @title    = attributes['title']
      @duration = Duration.new(attributes['duration'])
      @type     = attributes['type']
      @felt     = attributes['felt']
      @distance = Distance.new(attributes['distance'] || {})
    end

    def title(author_name)
      case @type
      when 'running'
        "#{author_name} ran #{@distance}"
      when 'cycling'
        "#{author_name} cycled #{@distance}"
      when 'swimming'
        "#{author_name} swam #{@distance}"
      when 'walking'
        "#{author_name} walked #{@distance}"
      when 'fitness'
        "#{author_name} worked out"
      end
    end

    def to_html
      content = []
      content.push "<h1>#{@title}</h1>" if @title

      case @type
      when 'running'
        content.push "<p>Ran #{@distance} in #{@duration} and felt #{@felt}.</p>"
      when 'cycling'
        content.push "<p>Cycled #{@distance} in #{@duration} and felt #{@felt}.</p>"
      when 'swimming'
        content.push "<p>Swam #{@distance} in #{@duration} and felt #{@felt}.</p>"
      when 'walking'
        content.push "<p>Walked #{@distance} in #{@duration} and felt #{@felt}.</p>"
      when 'fitness'
        content.push "<p>Worked out and felt #{@felt}.</p>"
      end

      content.join("\n\n")
    end
  end
end
