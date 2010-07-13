module EnFuego
  class User
    class << self
      def find_by_oauth_token(oauth_token)
        registry[oauth_token]
      end

      def create(attributes)
        registry[attributes[:oauth_token]] = new(attributes)
      end

      private

      def registry
        @registry ||= {}
      end
    end

    def initialize(attributes)
      @attributes = attributes
    end

    def oauth_token
      @attributes[:oauth_token]
    end
  end
end
