module EnFuego
  class User < Sequel::Model
    def before_create
      self.api_key =
        Digest::SHA1.hexdigest("#{rand}-#{Time.now}-#{rand}")
      super
    end

    def fetch_entries(consumer)
      raw_json = access_token(consumer).get('/entries/friends.json').body
      Entry.from_json(raw_json)
    end

    def post_entry(consumer, attributes)
      access_token(consumer).post('/entries.json', attributes.to_json, 'Accept' => 'application/json', 'Content-Type' => 'application/json')
    end

    private

    def access_token(consumer)
      OAuth::AccessToken.new(consumer, oauth_token, oauth_token_secret)
    end
  end
end
