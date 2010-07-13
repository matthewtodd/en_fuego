module EnFuego
  class DailyMile

    class << self
      def get_request_token
        consumer.get_request_token
      end

      def load_request_token(params)
        OAuth::RequestToken.from_hash(consumer, params)
      end

      private

      def consumer
        OAuth::Consumer.new(
          ENV['OAUTH_TOKEN'],
          ENV['OAUTH_TOKEN_SECRET'],
          :site => 'http://api.dailymile.com'
        )
      end
    end

  end
end
