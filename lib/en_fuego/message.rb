module EnFuego
  class Message
    def initialize(message)
      @message = message
    end

    def to_html
      "<p>#{@message.strip.gsub("\n", '<br />')}</p>"
    end
  end
end
