module EnFuego
  class User
    class << self
      def find(key)
        registry[key]
      end

      def find_by_identity_url(identity_url)
        registry.values.find do |user|
          user.identity_url == identity_url
        end
      end

      def create(attributes)
        user = new(attributes)
        registry[user.to_key] = user
        user
      end

      private

      def registry
        @registry ||= {}
      end
    end

    def initialize(attributes)
      @attributes = attributes
    end

    def identity_url
      @attributes[:identity_url]
    end

    def to_key
      identity_url
    end
  end
end
