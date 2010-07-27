module EnFuego
  class Distance
    def initialize(attributes)
      @value = attributes['value']
      @units = attributes['units']
    end

    def to_s
      if @value
        "#{@value} #{@units}"
      else
        'an unknown distance'
      end
    end
  end
end
