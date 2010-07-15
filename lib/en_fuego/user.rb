module EnFuego
  class User
    class << self
      def find_by_identity_url(identity_url)
        registry[identity_url]
      end

      def create(attributes)
        registry[attributes[:identity_url]] = new(attributes)
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
  end
end
