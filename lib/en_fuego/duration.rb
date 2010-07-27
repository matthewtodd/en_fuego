module EnFuego
  class Duration
    def initialize(value)
      @value = value
    end

    def to_s
      if @value
        minutes, seconds = @value.to_i.divmod(60)
        hours, minutes   = minutes.divmod(60)

        if hours > 0
          '%d:%02d:%02d' % [hours, minutes, seconds]
        else
          '%d:%02d' % [minutes, seconds]
        end
      else
        'an unknown time'
      end
    end
  end
end
