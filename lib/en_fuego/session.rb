module EnFuego
  module Session
    def request_token(consumer, token)
      oauth_token        = self[:oauth_token]
      oauth_token_secret = self[:oauth_token_secret]

      if token == oauth_token
        OAuth::RequestToken.new(consumer, oauth_token, oauth_token_secret)
      else
        nil
      end
    end

    def request_token=(request_token)
      if request_token
        self[:oauth_token]        = request_token.token
        self[:oauth_token_secret] = request_token.secret
      else
        self[:oauth_token]        = nil
        self[:oauth_token_secret] = nil
      end
    end

    def user
      if key = self[:user]
        User.find(key)
      else
        nil
      end
    end

    def user=(user)
      if user
        self[:user] = user.to_key
      else
        self[:user] = nil
      end
    end

    def user_attributes
      self[:user_attributes] || {}
    end

    def user_attributes=(user_attributes)
      self[:user_attributes] = user_attributes
    end
  end
end
